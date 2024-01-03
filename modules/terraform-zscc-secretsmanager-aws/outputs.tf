output "secret_id" {
  description = "Secrets Manager Secret ARN"
  value       = var.byo_secret ? data.aws_secretsmanager_secret.cloud_connector_secret_selected[0].id : aws_secretsmanager_secret.cloud_connector_secret[0].id
}

output "secret_name" {
  description = "Secrets Manager Secret friendly name"
  value       = var.byo_secret ? data.aws_secretsmanager_secret.cloud_connector_secret_selected[0].name : aws_secretsmanager_secret.cloud_connector_secret[0].name
}
