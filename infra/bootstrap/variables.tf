variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "service_name" {
  type    = string
  default = "fcg-users-service"
}

variable "github_repo" {
  description = "owner/repo autorizado a assumir a role via OIDC"
  type        = string
  default     = "FIAP-POS-TECH-TEAM-10/fcg-users-service"
}

variable "deploy_role_name" {
  description = "Nome da role assumida pelos workflows (tem que bater com ROLE_TO_ASSUME nos .yml)"
  type        = string
  default     = "GitHubActions-ECS-Deploy-Role"
}
