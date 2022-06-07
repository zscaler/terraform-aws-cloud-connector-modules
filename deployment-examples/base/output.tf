locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}:/home/centos/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}

3) SSH to the server host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

All Workload IPs. Replace private IP below with centos@"ip address" in ssh example command above.
${join("\n", module.workload.private_ip)}

VPC:          ${aws_vpc.vpc1.id}
NAT GW IP:    ${aws_nat_gateway.ngw[0].public_ip}

All NAT GW IPs:
${join("\n", aws_nat_gateway.ngw.*.public_ip)}

TB
}

output "testbedconfig" {
  value = local.testbedconfig
}

resource "local_file" "testbed" {
  content = local.testbedconfig
  filename = "testbed.txt"
}