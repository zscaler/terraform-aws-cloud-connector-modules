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
%{for spoke_key, spoke in local.active_spokes~}
${spoke.name} VPC: ${aws_vpc.spoke[spoke_key].id}
%{endfor~}

%{for spoke_key, spoke in local.active_spokes~}

${upper(spoke.name)} BASTION Jump Host Details/Commands:
1) Copy the SSH key to ${upper(spoke.name)} BASTION home directory
scp -F ssh_config ${var.name_prefix}-key-${random_string.suffix.result}.pem ${spoke.name}-bastion:~/.

2) SSH to ${upper(spoke.name)} BASTION
ssh -F ssh_config ${spoke.name}-bastion

${upper(spoke.name)} BASTION Instance ID:
${module.spoke_bastion[spoke_key].instance_id}


${upper(spoke.name)} WORKLOAD Details/Commands:
SSH to ${upper(spoke.name)} WORKLOADS
%{for k, v in local.spoke_workload_maps[spoke_key]~}
ssh -F ssh_config ${spoke.name}-workload-${k}
%{endfor~}

${upper(spoke.name)} WORKLOAD IPs:
%{for k, v in local.spoke_workload_maps[spoke_key]~}
${spoke.name}-workload-${k} = ${v}
%{endfor~}

${upper(spoke.name)} WORKLOAD Instance IDs:
${join("\n", module.spoke_workload[spoke_key].instance_id)}
%{endfor~}
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

output "spoke_vpc_ids" {
  description = "Spoke VPC IDs (populated only when tgw_enabled = true)"
  value       = { for k, v in aws_vpc.spoke : k => v.id }
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

  # Build per-spoke workload IP maps for testbed output
  spoke_workload_maps = {
    for spoke_key, spoke in local.active_spokes :
    spoke_key => {
      for index, ip in try(module.spoke_workload[spoke_key].private_ip, []) :
      index => ip
    }
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
%{for spoke_key, spoke in local.active_spokes~}
Host ${spoke.name}-bastion
      HostName ${module.spoke_bastion[spoke_key].public_dns}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
    %{for k, v in local.spoke_workload_maps[spoke_key]~}
Host ${spoke.name}-workload-${k}
      HostName ${v}
      User ec2-user
      IdentityFile ${var.name_prefix}-key-${random_string.suffix.result}.pem
      StrictHostKeyChecking no
      ProxyJump ${spoke.name}-bastion
      ProxyCommand ssh ${spoke.name}-bastion -W %h:%p
    %{endfor~}

%{endfor~}
    %{endif~}
  SSH_CONFIG
}
