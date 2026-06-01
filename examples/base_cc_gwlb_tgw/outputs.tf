locals {

  testbedconfig = <<TB
***Disclaimer***
By default, these templates store two critical files to the "examples" directory. DO NOT delete/lose these files:
1. Terraform State file (terraform.tfstate) - Terraform must store state about your managed infrastructure and configuration. 
   This state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures.
   Terraform uses state to determine which changes to make to your infrastructure. 
   Prior to any operation, Terraform does a refresh to update the state with the real infrastructure.
   If this file is missing, you will NOT be able to make incremental changes to the environment resources without first importing state back to terraform manually.
2. SSH Private Key (.pem) file - Zscaler templates will attempt to create a new local private/public key pair for VM access (if a pre-existing one is not specified). 
   You (and subsequently Zscaler) will NOT be able to remotely access these VMs once deployed without valid SSH access.
***Disclaimer***

1) Copy the SSH key to the Hub CC bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}:/home/ec2-user/.

1) Copy the SSH key to the Spoke 1 bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_1_bastion.public_dns}:/home/ec2-user/.

1) Copy the SSH key to the Spoke 2 bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_2_bastion.public_dns}:/home/ec2-user/.


2) SSH to the bastion host for Hub CC VPC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}

2) SSH to the bastion host spoke 1 VPC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_1_bastion.public_dns}

2) SSH to the bastion host spoke 2 VPC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_2_bastion.public_dns}

3) SSH to the Cloud Connectors
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc_vm.management_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}"

All CC Management IPs. Replace private IP below with zsroot@"ip address" in ssh example command above.
${join("\n", module.cc_vm.management_ip)}

4) SSH to the workload host in spoke 1 VPC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_1_workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_1_bastion.public_dns}"

All Workload IPs spoke 1. Replace private IP below with ec2-user@"ip address" in ssh example command above.
${join("\n", module.spoke_1_workload.private_ip)}

4) SSH to the workload host in spoke 2 VPC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_2_workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.spoke_2_bastion.public_dns}"

All Workload IPs spoke 2. Replace private IP below with ec2-user@"ip address" in ssh example command above.
${join("\n", module.spoke_2_workload.private_ip)}


Hub CC VPC:
${aws_vpc.hub.id}

Hub CC VPC - TGW Attach Subnets (per AZ):
${join("\n", aws_subnet.hub_tgw_attach[*].id)}

Hub CC VPC - GWLB Endpoint Subnets (per AZ):
${join("\n", aws_subnet.hub_gwlb_endpoint[*].id)}

Hub CC VPC - CC Subnets (per AZ):
${join("\n", aws_subnet.hub_cc[*].id)}

spoke 1 VPC:
${aws_vpc.spoke_1.id}

spoke 2 VPC:
${aws_vpc.spoke_2.id}

Transit Gateway ID:
${aws_ec2_transit_gateway.tgw.id}

TGW Attachment - Hub:
${aws_ec2_transit_gateway_vpc_attachment.hub.id}

TGW Attachment - Spoke 1:
${aws_ec2_transit_gateway_vpc_attachment.spoke_1.id}

TGW Attachment - Spoke 2:
${aws_ec2_transit_gateway_vpc_attachment.spoke_2.id}

TGW Spoke Route Table:
${aws_ec2_transit_gateway_route_table.spoke_rt.id}

TGW Hub Route Table:
${aws_ec2_transit_gateway_route_table.hub_rt.id}

All CC AZs:
${join("\n", distinct(module.cc_vm.availability_zone))}

All CC Instance IDs:
${join("\n", module.cc_vm.id)}

All CC Forwarding/Service IPs:
${join("\n", module.cc_vm.forwarding_ip)} 

All CC Forwarding/Service ENIs:
${join("\n", module.cc_vm.forwarding_eni)}

Hub NAT GW Public IPs (per AZ):
${join("\n", aws_eip.hub_ngw_eip[*].public_ip)}

GWLB Endpoint Service Name:
${module.gwlb_endpoint.vpce_service_name}

GWLB Endpoint Service ARN:
${module.gwlb_endpoint.vpce_service_arn}

GWLB Endpoint in Hub VPC:
${join("\n", module.gwlb_endpoint.gwlbe)}

GWLB ARN:
${module.gwlb.gwlb_arn}

All CC IAM Role ARNs:
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
