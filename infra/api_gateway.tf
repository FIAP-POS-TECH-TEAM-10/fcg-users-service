# 1. Definição da HTTP API (v2) - Ideal para Free Tier
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.service_name}-api-gateway"
  protocol_type = "HTTP"
  description   = "API Gateway para o serviço de Catalogo FCGames"
}

# Captura o DNS Público do servidor EC2 rodando o ECS
data "aws_instances" "ecs_instances" {
  instance_tags = {
    Name = "${var.service_name}-ecs-host"
  }

  instance_state_names = ["running"]
  depends_on           = [aws_autoscaling_group.ecs_asg]
}

# 2. Integração do API Gateway com o IP público/DNS da sua EC2 do ECS
# O API Gateway fará o proxy das chamadas HTTPS diretamente para a sua porta 5001
resource "aws_apigatewayv2_integration" "ecs_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "http://${data.aws_instances.ecs_instances.public_ips[0]}:5001"
  integration_method = "ANY"
}

# 3. Rota Coringa ({proxy+}) para repassar todos os endpoints (/swagger, /api/v1/...) para o ECS
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ecs_integration.id}"
}

# Rota para a raiz (/)
resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.ecs_integration.id}"
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

  access_log_settings {
    # ATENÇÃO: Adicionado o ":*" ao final do ARN para liberar a criação das Streams de log
    destination_arn = "${aws_cloudwatch_log_group.api_gw_logs.arn}:*"

    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      integrationStatus       = "$context.integrationStatus"
      latency                 = "$context.responseLatency"
    })
  }

  depends_on = [
    aws_api_gateway_account.account,
    aws_cloudwatch_log_resource_policy.api_gw_logging_policy
  ]
}