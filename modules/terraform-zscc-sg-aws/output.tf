output "mgmt_security_group_id" {
  value = aws_security_group.cc-mgmt-sg.*.id
}

output "mgmt_security_group_arn" {
  value = aws_security_group.cc-mgmt-sg.*.arn
}

output "service_security_group_id" {
  value = aws_security_group.cc-service-sg.*.id
}

output "service_security_group_arn" {
  value = aws_security_group.cc-service-sg.*.arn
}