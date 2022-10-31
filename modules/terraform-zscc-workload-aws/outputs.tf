output "private_ip" {
  description = "Instance Private IP"
  value       = aws_instance.server_host.*.private_ip
}
