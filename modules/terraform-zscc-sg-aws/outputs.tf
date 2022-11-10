output "mgmt_security_group_id" {
  description = "Instance Management Security Group ID"
  value       = data.aws_security_group.cc_mgmt_sg_selected[*].id
}

output "mgmt_security_group_arn" {
  description = "Instance Management Security Group ARN"
  value       = data.aws_security_group.cc_mgmt_sg_selected[*].arn
}

output "service_security_group_id" {
  description = "Instance Service Security Group ID"
  value       = data.aws_security_group.cc_service_sg_selected[*].id
}

output "service_security_group_arn" {
  description = "Instance Service Security Group ARN"
  value       = data.aws_security_group.cc_service_sg_selected[*].arn
}
