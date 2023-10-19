output "availability_zone" {
  description = "Instance Availability Zone"
  value       = aws_instance.cc_vm[*].availability_zone
}

output "id" {
  description = "EC2 Instance ID"
  value       = aws_instance.cc_vm[*].id
}

output "forwarding_eni" {
  description = "Instance Device Index 0 Network ID"
  value       = aws_network_interface.cc_vm_nic_index_0[*].id
}

output "forwarding_ip" {
  description = "Instance Forwarding/Service IP"
  value       = aws_instance.cc_vm[*].private_ip
}

output "management_eni" {
  description = "Instance Device Index 1 Network ID"
  value       = aws_network_interface.cc_vm_nic_index_1[*].id
}

output "management_ip" {
  description = "Instance Device Index 1 Private IP"
  value       = aws_network_interface.cc_vm_nic_index_1[*].private_ip
}
