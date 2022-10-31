locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}:/home/ec2-user/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}

3) SSH to the Cloud Connectors
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@<< CC mgmt IP >> -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}"
Note: Due to the dynamic nature of autoscaling groups, you will need to login to the AWS console and identify the mgmt IP (network interface device index #1) for each CC deployed and insert into the above command replacing "<< CC mgmt IP >>"
Note: You can also login to the Cloud Connectors directly from the AWS Console via Session Manager.

4) SSH to the server host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}"

All Workload IPs. Replace private IP below with ec2-user@"ip address" in ssh example command above.
${join("\n", module.workload.private_ip)}

VPC:         
${module.network.vpc_id}

All CC AZs:
${join("\n", distinct(module.cc_asg.availability_zone))}

All NAT GW IPs:
${join("\n", module.network.nat_gateway_ips)}

GWLB Endpoint Service Name:
${module.gwlb_endpoint.vpce_service_name}

All GWLB Endpoint IDs:
${join("\n", module.gwlb_endpoint.gwlbe)}

GWLB:
${module.gwlb.gwlb_arn}

All CC IAM Role ARNs (Please provide this to Zscaler for callhome enablement):
${join("\n", module.cc_iam.iam_instance_profile_arn)}

TB
}

output "testbedconfig" {
  description = "AWS Testbed results"
  value       = local.testbedconfig
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "../testbed.txt"
}
