output "private_ip" {
  description = "Instance Private IP"
  value       = aws_instance.cc_vm[*].private_ip
}

output "availability_zone" {
  description = "Instance Availability Zone"
  value       = aws_instance.cc_vm[*].availability_zone
}

output "service_eni_1" {
  description = "Instance Device Index 1 Network ID"
  value       = aws_network_interface.cc_vm_nic_index_1[*].id
}

output "id" {
  description = "Instance ID"
  value       = aws_instance.cc_vm[*].id
}

output "cc_service_private_ip" {
  description = "Instance Device Index 1 Private IP"
  value       = aws_network_interface.cc_vm_nic_index_1[*].private_ip
}
