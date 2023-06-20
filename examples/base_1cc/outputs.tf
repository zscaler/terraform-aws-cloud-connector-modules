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

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}:/home/ec2-user/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}

3) SSH to the CC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc_vm.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}"

All CC Management IPs. Replace private IP below with zsroot@"ip address" in ssh example command above.
${join("\n", module.cc_vm.private_ip)}

4) SSH to the workload host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}"

All Workload IPs. Replace private IP below with ec2-user@"ip address" in ssh example command above.
${join("\n", module.workload.private_ip)}

VPC:         
${module.network.vpc_id}

All CC AZs:
${join("\n", distinct(module.cc_vm.availability_zone))}

All CC Instance IDs:
${join("\n", module.cc_vm.id)}

All CC Primary Service IPs:
${join("\n", module.cc_vm.cc_service_private_ip)}

All CC Service ENIs:
${join("\n", module.cc_vm.service_eni_1)}

All NAT GW IPs:
${join("\n", module.network.nat_gateway_ips)}

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
