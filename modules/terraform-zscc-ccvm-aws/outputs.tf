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

output "service_eni_2" {
  description = "Instance Device Index 2 Network ID"
  value       = aws_network_interface.cc_vm_nic_index_2[*].id
}

output "service_eni_3" {
  description = "Instance Device Index 3 Network ID"
  value       = aws_network_interface.cc_vm_nic_index_3[*].id
}

output "service_eni_4" {
  description = "Instance Device Index 4 Network ID"
  value       = aws_network_interface.cc_vm_nic_index_4[*].id
}

output "id" {
  description = "Instance ID"
  value       = aws_instance.cc_vm[*].id
}

output "cc_service_private_ip" {
  description = "Instance Device Index 1 Private IP"
  value       = aws_network_interface.cc_vm_nic_index_1[*].private_ip
}

output "cc_med_lrg_service_1_private_ip" {
  description = "Instance Device Index 2 Private IP"
  value       = aws_network_interface.cc_vm_nic_index_2[*].private_ip
}

output "cc_med_lrg_service_2_private_ip" {
  description = "Instance Device Index 3 Private IP"
  value       = aws_network_interface.cc_vm_nic_index_3[*].private_ip
}

output "cc_lrg_service_3_private_ip" {
  description = "Instance Device Index 4 Private IP"
  value       = aws_network_interface.cc_vm_nic_index_4[*].private_ip
}
