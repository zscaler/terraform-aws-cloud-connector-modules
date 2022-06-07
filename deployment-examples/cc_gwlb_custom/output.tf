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
${join("\n", data.aws_nat_gateway.selected.*.public_ip)}

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