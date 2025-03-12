output "mgmt_security_group_id" {
  description = "Instance Management Security Group ID"
  value       = var.byo_security_group ? data.aws_security_group.cc_mgmt_sg_selected[*].id : aws_security_group.cc_mgmt_sg[*].id
}

output "mgmt_security_group_arn" {
  description = "Instance Management Security Group ARN"
  value       = var.byo_security_group ? data.aws_security_group.cc_mgmt_sg_selected[*].arn : aws_security_group.cc_mgmt_sg[*].arn
}

output "service_security_group_id" {
  description = "Instance Service Security Group ID"
  value       = var.byo_security_group ? data.aws_security_group.cc_service_sg_selected[*].id : aws_security_group.cc_service_sg[*].id
}

output "service_security_group_arn" {
  description = "Instance Service Security Group ARN"
  value       = var.byo_security_group ? data.aws_security_group.cc_service_sg_selected[*].arn : aws_security_group.cc_service_sg[*].arn
}

output "outbound_endpoint_security_group_id" {
  description = "Route53 DNS Resolver Outbound Endpoint Security Group ID"
  value       = var.byo_security_group && var.zpa_enabled ? data.aws_security_group.outbound_endpoint_sg_selected[*].id : aws_security_group.outbound_endpoint_sg[*].id
}

output "outbound_endpoint_security_group_arn" {
  description = "Route53 DNS Resolver Outbound Endpoint Security Group ARN"
  value       = var.byo_security_group && var.zpa_enabled ? data.aws_security_group.outbound_endpoint_sg_selected[*].arn : aws_security_group.outbound_endpoint_sg[*].arn
}
