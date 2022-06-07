output "private_ip" {
  value = aws_instance.cc-vm.*.private_ip
}

output availability_zone {
  value = aws_instance.cc-vm.*.availability_zone
}

output "service_eni_1" {
  value = aws_network_interface.cc-vm-nic-index-1.*.id
}

output "service_eni_2" {
  value = aws_network_interface.cc-vm-nic-index-2.*.id
}

output "service_eni_3" {
  value = aws_network_interface.cc-vm-nic-index-3.*.id
}

output "service_eni_4" {
  value = aws_network_interface.cc-vm-nic-index-4.*.id
}

output "id" {
  value = aws_instance.cc-vm.*.id
}

output "cc_service_private_ip" {
  value = data.aws_network_interface.cc-vm-nic-index-1-eni.*.private_ip
}

output "cc_med_lrg_service_1_private_ip" {
  value = data.aws_network_interface.cc-vm-nic-index-2-eni.*.private_ip
}

output "cc_med_lrg_service_2_private_ip" {
  value = data.aws_network_interface.cc-vm-nic-index-3-eni.*.private_ip
}

output "cc_lrg_service_3_private_ip" {
  value = data.aws_network_interface.cc-vm-nic-index-4-eni.*.private_ip
}

output "iam_arn" {
  value = aws_iam_role.cc-node-iam-role.*.arn
}