terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto centralizado (S3 + DynamoDB)
  backend "s3" {
    bucket         = "fiap-tech-challenge-tfstate-123456-915153720516-sa-east-1-an" # Substitua pelo seu Bucket S3
    key            = "users-service/terraform.tfstate" # Key exclusiva deste microsserviço
    region         = "sa-east-1"                          # Sua região AWS
    dynamodb_table = "fiap-tech-challenge-tflocks"        # Nome da sua tabela DynamoDB
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Cria a definição do segredo no Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "prod/minha-app/db"
  description = "Credenciais do banco de dados para a aplicacao fcg-users-service"
  
  # Força a exclusão imediata caso aplique um destroy (bom para ambientes de teste)
  recovery_window_in_days = 0 
}

# 2. Insere os valores de Chave/Valor dentro do segredo (Formato JSON)
resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    DB_PASSWORD = "SuaSenhaSuperSeguraAqui"
    DB_USER     = "admin"
  })
}