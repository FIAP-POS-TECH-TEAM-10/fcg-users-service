# --- VARIÁVEIS GLOBAIS ---
variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "service_name" {
  type    = string
  default = "fcg-users-service"
}

variable "db_connection" {
  description = "Connection string do banco, armazenada como DB_CONNECTION no AWS Secrets Manager."
  type        = string
  sensitive   = true
}
