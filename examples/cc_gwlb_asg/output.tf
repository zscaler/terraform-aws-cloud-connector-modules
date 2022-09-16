locals {

  testbedconfig = <<TB


VPC:         
${module.network.vpc_id}

All CC AZs:
${join("\n", distinct(module.cc-asg.availability_zone))}

All NAT GW IPs:
${join("\n", module.network.nat_gateway_ips)}

All GWLB Endpoint IDs:
${join("\n", module.gwlb-endpoint.gwlbe)}

GWLB Endpoint Service Name:
${module.gwlb-endpoint.vpce_service_name}

GWLB:
${module.gwlb.gwlb_arn}

All CC IAM Role ARNs (Please provide this to Zscaler for callhome enablement):
${join("\n", module.cc-iam.iam_instance_profile_arn)}

TB
}

output "testbedconfig" {
  value = local.testbedconfig
}


resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "../testbed.txt"
}