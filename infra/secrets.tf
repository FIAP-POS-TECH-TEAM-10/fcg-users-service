resource "aws_secretsmanager_secret" "users_credentials" {
  name        = "${var.service_name}-credentials"
  description = "Credenciais e configuracoes sensiveis do ${var.service_name}"

  tags = {
    Environment = "FreeTier-Study"
    Service     = var.service_name
  }
}