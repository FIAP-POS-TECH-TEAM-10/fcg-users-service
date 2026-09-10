terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto centralizado (S3 + DynamoDB) — criado por infra/bootstrap
  backend "s3" {
    bucket         = "fcg-users-service-tfstate-704516098616-sa-east-1" # bootstrap: output tfstate_bucket
    key            = "users-service/terraform.tfstate"                  # Key exclusiva deste microsserviço
    region         = "sa-east-1"
    dynamodb_table = "fcg-users-service-tflocks"                        # bootstrap: output tflock_table
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}