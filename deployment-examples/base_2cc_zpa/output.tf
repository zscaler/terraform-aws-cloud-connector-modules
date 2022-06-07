locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}:/home/centos/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}

3) SSH to the CC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm.private_ip[1]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

All CC Management IPs. Replace private IP below with zsroot@"ip address" in ssh example command above.
${join("\n", module.cc-vm.private_ip)}


4) SSH to the server host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.workload.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.workload.private_ip[1]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

All Workload IPs. Replace private IP below with centos@"ip address" in ssh example command above.
${join("\n", module.workload.private_ip)}

VPC: 
${aws_vpc.vpc1.id}

All CC AZs:
${join("\n", distinct(module.cc-vm.availability_zone))}

All CC Instance IDs:
${join("\n", module.cc-vm.id)}

All CC Primary Service IPs:
${join("\n", module.cc-vm.cc_service_private_ip)}

All CC Service ENIs:
${join("\n", module.cc-vm.service_eni_1)}

All NAT GW IPs:
${join("\n", aws_nat_gateway.ngw.*.public_ip)}

All CC IAM Role ARNs (Please provide this to Zscaler for callhome enablement):
${join("\n", module.cc-vm.iam_arn)}


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
            username: centos
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
  WORKER2:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.SshClientConnector
        via: fast
      fast:
        hostname: ${module.workload.private_ip[1]}
        port: 22
        username: ec2-user
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_dns}
            username: centos
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
            username: centos
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
  CC2:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.ZSNodeConnector
        via: fast
      fast:
        name: /sc/instances/edgeconnector0
        hostname: ${module.cc-vm.private_ip[1]}
        port: 22
        username: zsroot
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_dns}
            username: centos
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem          
TBP
}

resource "local_file" "testbed_yml" {
content = local.testbedconfigpyats
filename = "testbed.yml"
}

output "testbedconfig" {
  value = local.testbedconfig
}

resource "local_file" "testbed" {
  content = local.testbedconfig
  filename = "testbed.txt"
}