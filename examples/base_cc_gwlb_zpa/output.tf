locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}:/home/centos/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}

3) SSH to the EC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

All CC Management IPs. Replace private IP below with zsroot@"ip address" in ssh example command above.
${join("\n", module.cc-vm.private_ip)}


4) SSH to the server host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

All Workload IPs. Replace private IP below with centos@"ip address" in ssh example command above.
${join("\n", module.workload.private_ip)}

VPC: 
${aws_vpc.vpc1.id}

All CC AZs:
${join("\n", distinct(module.cc-vm.availability_zone))}

All CC Instance IDs:
${join("\n", module.cc-vm.id)}

All CC Service IPs:
Service Interface Device Index 1:
${join("\n", module.cc-vm.cc_service_private_ip)} 

Service Interface Device Index 2:
${join("\n", module.cc-vm.cc_med_lrg_service_1_private_ip)} 

Service Interface Device Index 3:
${join("\n", module.cc-vm.cc_med_lrg_service_2_private_ip)} 

Service Interface Device Index 4:
${join("\n", module.cc-vm.cc_lrg_service_3_private_ip)}

All CC Primary Service ENIs:
${join("\n", module.cc-vm.service_eni_1)}

All NAT GW IPs:
${join("\n", aws_nat_gateway.ngw.*.public_ip)}

All GWLB Endpoint IDs:
${join("\n", module.gwlb-endpoint.gwlbe)}

GWLB:
${module.gwlb.gwlb_arn}

All CC IAM Role ARNs (Please provide this to Zscaler for callhome enablement):
${join("\n", module.cc-vm.iam_arn)}

TB
}

output "testbedconfig" {
  value = local.testbedconfig
}


resource "local_file" "testbed" {
  content = local.testbedconfig
  filename = "testbed.txt"
}