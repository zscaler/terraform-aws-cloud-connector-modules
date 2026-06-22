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
SSH to CLOUD CONNECTOR
%{for k, v in local.cc_map~}
ssh -F ssh_config ccvm-${k}
%{endfor~}  

CLOUD CONNECTOR Management IPs:
%{for k, v in local.cc_map~}
ccvm-${k} = ${v}
%{endfor~}

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


WORKLOAD Details/Commands:
SSH to WORKLOADS
%{for k, v in local.workload_map~}
ssh -F ssh_config workload-${k}
%{endfor~}  

WORKLOAD IPs:
%{for k, v in local.workload_map~}
workload-${k} = ${v}
%{endfor~} 

WORKLOAD Instance IDs:
%{if !var.tgw_enabled~}
${join("\n", module.workload[0].instance_id)}
%{endif~}


BASTION Jump Host Details/Commands:
1) Copy the SSH key to BASTION home directory
scp -F ssh_config ${var.name_prefix}-key-${random_string.suffix.result}.pem bastion:~/.

2) SSH to BASTION
ssh -F ssh_config bastion

BASTION Instance ID:
${module.bastion.instance_id}


VPC:         
${module.network.vpc_id}

Zscaler Subnet IDs:
${join("\n", module.network.cc_subnet_ids)}

All NAT GW IPs:
${join("\n", module.network.nat_gateway_ips)}

GWLB Endpoint Service Name:
${module.gwlb_endpoint.vpce_service_name}

GWLB Endpoint Service ARN:
${module.gwlb_endpoint.vpce_service_arn}

All GWLB Endpoint IDs:
${join("\n", module.gwlb_endpoint.gwlbe)}

GWLB ARN:
${module.gwlb.gwlb_arn}
%{if var.tgw_enabled~}

TRANSIT GATEWAY:
TGW ID: ${module.tgw[0].tgw_id}
Hub VPC: ${module.network.vpc_id}
Spoke 1 VPC: ${aws_vpc.spoke_1[0].id}
Spoke 2 VPC: ${aws_vpc.spoke_2[0].id}


SPOKE 1 BASTION Jump Host Details/Commands:
1) Copy the SSH key to SPOKE 1 BASTION home directory
scp -F ssh_config ${var.name_prefix}-key-${random_string.suffix.result}.pem spoke-1-bastion:~/.

2) SSH to SPOKE 1 BASTION
ssh -F ssh_config spoke-1-bastion

SPOKE 1 BASTION Instance ID:
${module.spoke_1_bastion[0].instance_id}


SPOKE 1 WORKLOAD Details/Commands:
SSH to SPOKE 1 WORKLOADS
%{for k, v in local.spoke_1_workload_map~}
ssh -F ssh_config spoke-1-workload-${k}
%{endfor~}

SPOKE 1 WORKLOAD IPs:
%{for k, v in local.spoke_1_workload_map~}
spoke-1-workload-${k} = ${v}
%{endfor~}

SPOKE 1 WORKLOAD Instance IDs:
${join("\n", module.spoke_1_workload[0].instance_id)}


SPOKE 2 BASTION Jump Host Details/Commands:
1) Copy the SSH key to SPOKE 2 BASTION home directory
scp -F ssh_config ${var.name_prefix}-key-${random_string.suffix.result}.pem spoke-2-bastion:~/.

2) SSH to SPOKE 2 BASTION
ssh -F ssh_config spoke-2-bastion

SPOKE 2 BASTION Instance ID:
${module.spoke_2_bastion[0].instance_id}


SPOKE 2 WORKLOAD Details/Commands:
SSH to SPOKE 2 WORKLOADS
%{for k, v in local.spoke_2_workload_map~}
ssh -F ssh_config spoke-2-workload-${k}
%{endfor~}

SPOKE 2 WORKLOAD IPs:
%{for k, v in local.spoke_2_workload_map~}
spoke-2-workload-${k} = ${v}
%{endfor~}

SPOKE 2 WORKLOAD Instance IDs:
${join("\n", module.spoke_2_workload[0].instance_id)}
%{endif~}

TB
}

output "testbedconfig" {
  description = "AWS Testbed results"
  value       = local.testbedconfig
}

output "tgw_id" {
  description = "Transit Gateway ID (populated only when tgw_enabled = true)"
  value       = try(module.tgw[0].tgw_id, null)
}

output "hub_vpc_id" {
  description = "Hub VPC ID"
  value       = module.network.vpc_id
}

output "tgw_attach_subnet_ids" {
  description = "TGW Attach Subnet IDs (populated only when tgw_enabled = true)"
  value       = module.network.tgw_attach_subnet_ids
}

output "gwlb_endpoint_subnet_ids" {
  description = "GWLB Endpoint Subnet IDs in Hub VPC (populated only when tgw_enabled = true)"
  value       = module.network.gwlb_endpoint_subnet_ids
}

output "spoke_1_vpc_id" {
  description = "Spoke 1 VPC ID (populated only when tgw_enabled = true)"
  value       = try(aws_vpc.spoke_1[0].id, null)
}

output "spoke_2_vpc_id" {
  description = "Spoke 2 VPC ID (populated only when tgw_enabled = true)"
  value       = try(aws_vpc.spoke_2[0].id, null)
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "../testbed.txt"
}

resource "local_file" "ssh_config" {
  content  = local.ssh_config_contents
  filename = "../ssh_config"
}

locals {
  workload_map = {
    for index, ip in try(module.workload[0].private_ip, []) :
    index => ip
  }
  spoke_1_workload_map = {
    for index, ip in try(module.spoke_1_workload[0].private_ip, []) :
    index => ip
  }
  spoke_2_workload_map = {
    for index, ip in try(module.spoke_2_workload[0].private_ip, []) :
    index => ip
  }
  cc_map = {
    for index, ip in module.cc_vm.management_ip :
    index => ip
  }
  ssh_config_contents = <<SSH_CONFIG
    Host bastion
      HostName ${module.bastion.public_dns}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
    %{for k, v in local.workload_map~}
Host workload-${k}
      HostName ${v}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
      StrictHostKeyChecking no
      ProxyJump bastion
      ProxyCommand ssh bastion -W %h:%p
    %{endfor~}

    %{for k, v in local.cc_map~}
Host ccvm-${k}
      HostName ${v}
      User zsroot
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
      StrictHostKeyChecking no
      ProxyJump bastion        
      ProxyCommand ssh bastion -W %h:%p
    %{endfor~}

    %{if var.tgw_enabled~}
Host spoke-1-bastion
      HostName ${module.spoke_1_bastion[0].public_dns}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
    %{for k, v in local.spoke_1_workload_map~}
Host spoke-1-workload-${k}
      HostName ${v}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
      StrictHostKeyChecking no
      ProxyJump spoke-1-bastion
      ProxyCommand ssh spoke-1-bastion -W %h:%p
    %{endfor~}

Host spoke-2-bastion
      HostName ${module.spoke_2_bastion[0].public_dns}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
    %{for k, v in local.spoke_2_workload_map~}
Host spoke-2-workload-${k}
      HostName ${v}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
      StrictHostKeyChecking no
      ProxyJump spoke-2-bastion
      ProxyCommand ssh spoke-2-bastion -W %h:%p
    %{endfor~}
    %{endif~}
  SSH_CONFIG
}
