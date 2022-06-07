output "private_ip" {
  value = aws_instance.server_host.*.private_ip
}
