# ------------------------------------------------------------------------------
# 1. REDE PADRÃO E SECURITY GROUP
# ------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group liberando a porta da aplicação e HTTP
resource "aws_security_group" "ecs_sg" {
  name        = "${var.service_name}-ecs-sg"
  description = "Permite trafego de entrada para o container ECS"
  vpc_id      = data.aws_vpc.default.id

  # Portas dinamicas alocadas pelo ECS no modo bridge
  ingress {
    from_port   = 32768
    to_port     = 61000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Porta da aplicação
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# 2. CLOUDWATCH LOGS
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 7
}

# ------------------------------------------------------------------------------
# 3. IAM ROLE DA INSTANCIA EC2
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.service_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.service_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# ------------------------------------------------------------------------------
# 4. ECS TASK EXECUTION ROLE
# ------------------------------------------------------------------------------
#
# Essa role é usada pelo ECS Agent para obter recursos necessários para
# iniciar a task, incluindo secrets do AWS Secrets Manager.
#
# A aplicação NÃO usa essa role para acessar SQS/SNS.
# Para isso existe a ecs_task_role abaixo.
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.service_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Política padrão de execução do ECS
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Permissão específica para buscar os secrets do Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.service_name}-secrets-access"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadUsersSecrets"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_secretsmanager_secret.users_credentials.arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 5. ECS TASK ROLE
# ------------------------------------------------------------------------------
#
# Role usada pela aplicação dentro do container.
#
# Atualmente utilizada pelo MassTransit para SQS/SNS.
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.service_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_sqs_sns" {
  name = "${var.service_name}-task-sqs-sns"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "Sqs"
        Effect = "Allow"

        Action = [
          "sqs:CreateQueue",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:TagQueue",
          "sqs:ListQueueTags",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:PurgeQueue"
        ]

        Resource = "arn:aws:sqs:${var.aws_region}:*:*"
      },

      {
        Sid    = "Sns"
        Effect = "Allow"

        Action = [
          "sns:CreateTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:TagResource",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:Publish"
        ]

        Resource = "arn:aws:sns:${var.aws_region}:*:*"
      },

      {
        Sid    = "ListNoResourceLevelPerms"
        Effect = "Allow"

        Action = [
          "sqs:ListQueues",
          "sns:ListTopics"
        ]

        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 6. ECS CLUSTER
# ------------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

# ------------------------------------------------------------------------------
# 7. ECS-OPTIMIZED AMI
# ------------------------------------------------------------------------------

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# ------------------------------------------------------------------------------
# 8. LAUNCH TEMPLATE
# ------------------------------------------------------------------------------

resource "aws_launch_template" "ecs_ec2_template" {
  name_prefix   = "${var.service_name}-template-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash

              echo "ECS_CLUSTER=${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config
              EOF
  )
}

# ------------------------------------------------------------------------------
# 9. AUTO SCALING GROUP
# ------------------------------------------------------------------------------

resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.service_name}-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.ecs_ec2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.service_name}-ecs-host"
    propagate_at_launch = true
  }
}

# ------------------------------------------------------------------------------
# 10. ECS TASK DEFINITION
# ------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.service_name}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  cpu    = "256"
  memory = "256"

  # Role utilizada pela aplicação para acessar AWS em runtime
  task_role_arn = aws_iam_role.ecs_task_role.arn

  # Role utilizada pelo ECS para iniciar a task e buscar secrets
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "${var.service_name}-container"

      image = "${aws_ecr_repository.app_repo.repository_url}:latest"

      cpu       = 256
      memory    = 256
      essential = true

      # ------------------------------------------------------------------------
      # PORTA
      # ------------------------------------------------------------------------

      portMappings = [
        {
          containerPort = 5001
          hostPort      = 5001
          protocol      = "tcp"
        }
      ]

      # ------------------------------------------------------------------------
      # CONFIGURAÇÕES NÃO SENSÍVEIS
      # ------------------------------------------------------------------------

      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        },

        {
          name  = "ASPNETCORE_URLS"
          value = "http://+:5001"
        },

        {
          name  = "JWT__ISSUER"
          value = "AppFiapFcGames"
        },

        {
          name  = "RabbitMQ__Host"
          value = "rabbitmq"
        },

        {
          name  = "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT"
          value = "1"
        },

        {
          name  = "DOTNET_USE_POLLING_FILE_WATCHER"
          value = "true"
        },

        {
          name  = "Messaging__Provider"
          value = "Sqs"
        },

        {
          name  = "AWS__Region"
          value = var.aws_region
        }
      ]

      # ------------------------------------------------------------------------
      # SECRETS
      # ------------------------------------------------------------------------
      #
      # Cada variável abaixo recebe uma propriedade específica do JSON
      # armazenado no AWS Secrets Manager.
      #
      # Formato:
      #
      # ARN:chave-json::
      #
      # Os dois ":" finais indicam que estamos usando a versão AWSCURRENT.
      # ------------------------------------------------------------------------

      secrets = [
        {
          name = "JWT__KEY"

          valueFrom = "${aws_secretsmanager_secret.users_credentials.arn}:JWT__KEY::"
        },

        {
          name = "ConnectionStrings__DefaultConnection"

          valueFrom = "${aws_secretsmanager_secret.users_credentials.arn}:ConnectionStrings__DefaultConnection::"
        },

        {
          name = "RabbitMQ__Username"

          valueFrom = "${aws_secretsmanager_secret.users_credentials.arn}:RabbitMQ__Username::"
        },

        {
          name = "RabbitMQ__Password"

          valueFrom = "${aws_secretsmanager_secret.users_credentials.arn}:RabbitMQ__Password::"
        }
      ]

      # ------------------------------------------------------------------------
      # CLOUDWATCH LOGS
      # ------------------------------------------------------------------------

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ------------------------------------------------------------------------------
# 11. ECS SERVICE
# ------------------------------------------------------------------------------

resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = 1
  launch_type   = "EC2"

  # Permite que a task atual seja encerrada durante o deploy,
  # liberando a porta fixa 5001.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  lifecycle {
    ignore_changes = [
      # O GitHub Actions pode registrar novas revisões da Task Definition.
      task_definition
    ]
  }
}