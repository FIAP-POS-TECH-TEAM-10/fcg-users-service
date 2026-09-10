# ------------------------------------------------------------------------------
# BOOTSTRAP — recursos que o Terraform principal (../) assume que já existem.
#
# Roda com STATE LOCAL (arquivo terraform.tfstate nesta pasta), porque ele é
# quem CRIA o bucket S3 / tabela DynamoDB usados como backend remoto pelo
# Terraform principal. Rode UMA vez por conta AWS.
#
# Cria:
#   - Bucket S3 versionado para o tfstate            (backend do ../)
#   - Tabela DynamoDB para lock de state             (backend do ../)
#   - OIDC provider do GitHub Actions
#   - IAM Role GitHubActions-ECS-Deploy-Role         (assumida pelos workflows)
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  state_bucket = "${var.service_name}-tfstate-${local.account_id}-${var.aws_region}"
  lock_table   = "${var.service_name}-tflocks"
}

# ------------------------------------------------------------------------------
# 1. Backend remoto do Terraform principal
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket

  # Não deixa o `terraform destroy` apagar um bucket com histórico de state.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tflocks" {
  name         = local.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ------------------------------------------------------------------------------
# 2. OIDC provider do GitHub Actions
#    (só pode existir 1 por conta para esta URL — se já existir, ver README)
# ------------------------------------------------------------------------------
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# ------------------------------------------------------------------------------
# 3. Role assumida pelos workflows (deploy-on-pr-merge.yml etc.)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = var.deploy_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# Free-tier / desafio acadêmico: permissões amplas o suficiente para o Terraform
# principal criar ECR + ECS/EC2 + API Gateway + CloudWatch + backend S3/Dynamo.
resource "aws_iam_role_policy_attachment" "power_user" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# PowerUserAccess NÃO cobre IAM write — o Terraform principal cria roles/instance
# profiles (ECS instance role, API Gateway CW role). Escopado a nomes fcg-*.
resource "aws_iam_role_policy" "iam_for_infra" {
  name = "${var.service_name}-deploy-iam"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageInfraRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
          "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
          "iam:PassRole", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy",
          "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
          "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
          "iam:ListInstanceProfilesForRole", "iam:TagInstanceProfile"
        ]
        Resource = [
          "arn:aws:iam::${local.account_id}:role/${var.service_name}-*",
          "arn:aws:iam::${local.account_id}:instance-profile/${var.service_name}-*"
        ]
      },
      {
        Sid      = "ServiceLinkedRoles"
        Effect   = "Allow"
        Action   = ["iam:CreateServiceLinkedRole"]
        Resource = "*"
      },
      {
        Sid      = "ReadIam"
        Effect   = "Allow"
        Action   = ["iam:GetRole", "iam:ListRoles", "iam:GetOpenIDConnectProvider"]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Outputs — valores para colar no Terraform principal e nos workflows
# ------------------------------------------------------------------------------
output "tfstate_bucket" {
  description = "Bucket S3 -> backend \"s3\" { bucket = ... } em ../main.tf"
  value       = aws_s3_bucket.tfstate.id
}

output "tflock_table" {
  description = "Tabela DynamoDB -> backend \"s3\" { dynamodb_table = ... } em ../main.tf"
  value       = aws_dynamodb_table.tflocks.id
}

output "deploy_role_arn" {
  description = "ARN da role -> env ROLE_TO_ASSUME nos workflows .github/workflows/*.yml"
  value       = aws_iam_role.github_actions.arn
}

output "account_id" {
  description = "ID da conta AWS -> usado na imagem do .aws/task-definition.json"
  value       = local.account_id
}
