locals {

  testbedconfig = <<TB


VPC:         
${data.aws_vpc.selected.id}

All CC AZs:
${join("\n", distinct(module.cc-vm.availability_zone))}

All CC Instance IDs:
${join("\n", module.cc-vm.id)}

All CC Management IPs:
${join("\n", module.cc-vm.private_ip)}

All CC Primary Service IPs:
${join("\n", module.cc-vm.cc_service_private_ip)}

All CC Service ENIs:
${join("\n", module.cc-vm.service_eni_1)}

All NAT GW IPs:
${join("\n", data.aws_nat_gateway.selected.*.public_ip)}

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