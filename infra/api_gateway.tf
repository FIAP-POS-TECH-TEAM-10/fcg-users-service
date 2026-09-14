# 1. Definição da HTTP API (v2) - Ideal para Free Tier
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.service_name}-api-gateway"
  protocol_type = "HTTP"
  description   = "API Gateway para o serviço de Catalogo FCGames"
}

# Captura o IP público da EC2 que a ASG realmente controla — NÃO dá pra confiar em
# "qualquer instância com a tag X e estado running": quando a ASG substitui uma instância
# (novo AMI, unhealthy, ou intervenção manual), a antiga às vezes fica de pé por alguns
# minutos antes do EC2 terminar de verdade — e nesse intervalo as DUAS batem no mesmo
# filtro de tag+"running", e o provider pode escolher a errada (a que não tem a task do
# ECS rodando). Isso já causou o Gateway apontar pra instância errada (503 mesmo com tudo
# saudável) mais de uma vez, inclusive logo após um redeploy limpo. `aws_autoscaling_group`
# não expõe a lista de instâncias/lifecycle_state (só metadados agregados), então a forma
# confiável de desempatar é: entre as instâncias candidatas, a que a ASG controla é sempre
# a mais recentemente lançada (qualquer órfã é sobra de um ciclo anterior).
data "aws_instances" "ecs_host_candidates" {
  instance_tags = {
    Name = "${var.service_name}-ecs-host"
  }
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.ecs_asg.name]
  }

  instance_state_names = ["running"]
  depends_on           = [aws_autoscaling_group.ecs_asg]
}

data "aws_instance" "ecs_host_detail" {
  for_each    = toset(data.aws_instances.ecs_host_candidates.ids)
  instance_id = each.value
}

locals {
  # launch_time é ISO 8601 ("2026-09-14T23:14:06Z") — ordenação lexicográfica de string
  # já corresponde à ordem cronológica. Pega o public_ip da instância com o maior launch_time.
  ecs_host_by_launch_time = { for i in data.aws_instance.ecs_host_detail : i.launch_time => i.public_ip }
  ecs_host_ip             = local.ecs_host_by_launch_time[sort(keys(local.ecs_host_by_launch_time))[length(local.ecs_host_by_launch_time) - 1]]
}

# 2. Integração do API Gateway com o IP público da EC2 do ECS.
# `/{proxy}` no fim é obrigatório: sem isso a HTTP API repassa TODA requisição para a
# raiz "/" do backend (todo endpoint vira 404 — bug encontrado testando /health, /usuarios
# e /scalar/v1 direto: todos chegavam no app como RequestPath "/"). Com `{proxy}` ela injeta
# o caminho capturado pela rota `ANY /{proxy+}` (ex.: /health, /usuarios, /scalar/v1).
resource "aws_apigatewayv2_integration" "ecs_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${local.ecs_host_ip}:5001/{proxy}"
  integration_method     = "ANY"
  payload_format_version = "1.0"

  # A rota `ANY /` não tem a variável `proxy`; ela precisa ser repontada para a
  # integração raiz ANTES de esta integração ganhar `/{proxy}`, senão a AWS
  # rejeita a validação rota<->integração ("path variables ... not present in the route key").
  depends_on = [aws_apigatewayv2_route.root_route]
}

# 3. Rota coringa: repassa todos os endpoints (/health, /usuarios, /scalar/v1, ...) para o ECS.
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ecs_integration.id}"
}

# Rota para a raiz "/" — usa integração própria, forçando o path "/" no backend
# (não dá pra reaproveitar a integração com `{proxy}` sem um valor pra variável).
resource "aws_apigatewayv2_integration" "ecs_integration_root" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${local.ecs_host_ip}:5001/"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.ecs_integration_root.id}"
}

# Output para exibir a URL final gerada pelo API Gateway
output "api_gateway_url" {
  description = "URL HTTPS pública gerada pelo API Gateway (Free Tier)"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

# 1. Role do IAM para o serviço do API Gateway conseguir escrever no CloudWatch
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${var.service_name}-apigw-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Anexa a política gerenciada da AWS para gravação de logs
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# 3. Associa a Role criada às configurações globais do API Gateway da conta na região
resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn

  depends_on = [aws_iam_role_policy_attachment.api_gateway_cloudwatch_policy]
}

# 3. Política de Recurso que concede permissão EXPLÍCITA ao CloudWatch para o API Gateway
resource "aws_cloudwatch_log_resource_policy" "api_gw_logging_policy" {
  policy_name = "${var.service_name}-apigw-cw-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:ConfigureLogDelivery",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.api_gw_logs.arn}:*"
      }
    ]
  })
}

# 1. Log Group no CloudWatch para armazenar os Access Logs do API Gateway
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/${var.service_name}-api-gateway"
  retention_in_days = 7
}

# 2. Atualização do Stage $default com Access Logs habilitados
# Estágio Padrão ($default) com logs ativados
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    logging_level            = "INFO"
    detailed_metrics_enabled = true
    throttling_burst_limit   = 10000
    throttling_rate_limit    = 20000
  }

  access_log_settings {
    # ATENÇÃO: Adicionado o ":*" ao final do ARN para liberar a criação das Streams de log
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      path                    = "$context.path" # Rota real chamada (ex: /swagger/index.html)      
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      integrationStatus       = "$context.integrationStatus"
      integrationLatency      = "$context.integration.latency"
      errorMessage            = "$context.error.message"
      errorResponseType       = "$context.error.responseType"
      latency                 = "$context.responseLatency"
    })
  }

  depends_on = [
    aws_cloudwatch_log_resource_policy.api_gw_logging_policy
  ]
}