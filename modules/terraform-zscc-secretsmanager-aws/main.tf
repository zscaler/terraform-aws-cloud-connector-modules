################################################################################
# Create AWS Secrets Manager Secret and values for Cloud Connector provisioning
################################################################################ 
resource "aws_secretsmanager_secret" "cloud_connector_secret" {
  count       = var.byo_secret ? 0 : 1
  description = "Zscaler Cloud Connector Provisioning Secret"
  name        = coalesce(var.secret_name, "${var.name_prefix}-secret-${var.resource_tag}")

  tags = merge(var.global_tags)
}

resource "aws_secretsmanager_secret_version" "cloud_connector_secret_values" {
  count         = var.byo_secret ? 0 : 1
  secret_id     = aws_secretsmanager_secret.cloud_connector_secret[0].id
  secret_string = <<EOF
   {
    "username": "${var.zscaler_username}",
    "password": "${var.zscaler_password}",
    "api_key": "${var.zscaler_api_key}"
   }
EOF
}


# OR Retrieve Secret Manager ARN by customer provided friendly name
data "aws_secretsmanager_secret" "cloud_connector_secret_selected" {
  count = var.byo_secret ? 1 : 0
  name  = var.secret_name
}
