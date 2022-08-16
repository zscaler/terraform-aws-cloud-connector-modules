locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}:/home/ec2-user/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}

3) SSH to the CC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}"

All CC Management IPs. Replace private IP below with zsroot@"ip address" in ssh example command above.
${join("\n", module.cc-vm.private_ip)}


4) SSH to the server host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.bastion.public_dns}"

All Workload IPs. Replace private IP below with ec2-user@"ip address" in ssh example command above.
${join("\n", module.workload.private_ip)}

VPC:         
${module.network.vpc_id}

All CC AZs:
${join("\n", distinct(module.cc-vm.availability_zone))}

All CC Instance IDs:
${join("\n", module.cc-vm.id)}

All CC Primary Service IPs:
${join("\n", module.cc-vm.cc_service_private_ip)}

All CC Service ENIs:
${join("\n", module.cc-vm.service_eni_1)}

All NAT GW IPs:
${join("\n", module.network.nat_gateway_ips)}

All CC IAM Role ARNs (Please provide this to Zscaler for callhome enablement):
${join("\n", module.cc-iam.iam_instance_profile_arn)}

TB

  testbedconfigpyats = <<TBP
testbed:
  name: aws-${random_string.suffix.result}

devices:
  WORKER:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.SshClientConnector
        via: fast
      fast:
        hostname: ${module.workload.private_ip[0]}
        port: 22
        username: ec2-user
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_dns}
            username: ec2-user
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
  CC1:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.ZSNodeConnector
        via: fast
      fast:
        name: /sc/instances/edgeconnector0
        hostname: ${module.cc-vm.private_ip[0]}
        port: 22
        username: zsroot
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_dns}
            username: ec2-user
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
TBP
}

resource "local_file" "testbed_yml" {
  content  = local.testbedconfigpyats
  filename = "../testbed.yml"
}

output "testbedconfig" {
  value = local.testbedconfig
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "../testbed.txt"
}
