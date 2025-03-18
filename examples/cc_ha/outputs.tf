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

Login Instructions & Resource Attributes

CLOUD CONNECTOR Details/Commands:
CLOUD CONNECTOR Instance IDs:
${join("\n", module.cc_vm.id)}

CLOUD CONNECTOR Forwarding/Service IPs:
${join("\n", module.cc_vm.forwarding_ip)}

CLOUD CONNECTOR Forwarding/Service ENIs:
${join("\n", module.cc_vm.forwarding_eni)}

CLOUD CONNECTOR AZs:
${join("\n", distinct(module.cc_vm.availability_zone))}

CLOUD CONNECTOR IAM Role ARNs:
${join("\n", module.cc_iam.iam_instance_profile_arn)}


VPC:         
${module.network.vpc_id}

Zscaler Subnet IDs:
${join("\n", module.network.cc_subnet_ids)}

All NAT GW IPs:
${join("\n", module.network.nat_gateway_ips)}

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
