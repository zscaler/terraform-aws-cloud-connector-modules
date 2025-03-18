output "private_ip" {
  description = "Instance Private IP"
  value       = aws_instance.server_host[*].private_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server_host[*].id
}
