output "public_ip" {
  description = "Instance Public IP"
  value       = aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "Instance Public DNS"
  value       = aws_instance.bastion.public_dns
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.bastion.id
}
