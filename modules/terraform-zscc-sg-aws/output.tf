output "mgmt_security_group_id" {
  value = data.aws_security_group.cc-mgmt-sg-selected.*.id
}

output "mgmt_security_group_arn" {
  value = data.aws_security_group.cc-mgmt-sg-selected.*.arn
}

output "service_security_group_id" {
  value = data.aws_security_group.cc-service-sg-selected.*.id
}

output "service_security_group_arn" {
  value = data.aws_security_group.cc-service-sg-selected.*.arn
}