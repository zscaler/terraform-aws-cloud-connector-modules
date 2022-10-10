################################################################################
# Pull in VPC info
################################################################################
data "aws_vpc" "selected" {
  id = var.vpc_id
}


################################################################################
# Pull Amazon Linux 2 AMI for instance use
################################################################################
data "aws_ssm_parameter" "amazon_linux_latest" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


################################################################################
# Create IAM Assume Role, Policies, and Host/Instance Profiles
################################################################################
resource "aws_iam_role" "node_iam_role" {
  name = "${var.name_prefix}-node-iam-role-${var.resource_tag}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


################################################################################
# Define AWS Managed SSM Manager Policy
################################################################################
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/${var.iam_role_policy_ssmcore}"
  role       = aws_iam_role.node_iam_role.name
}


################################################################################
# Assign IAM Role to Instance Profile for Workload instance attachment
################################################################################
resource "aws_iam_instance_profile" "server_host_profile" {
  name = "${var.name_prefix}-server_host_profile-${var.resource_tag}"
  role = aws_iam_role.node_iam_role.name
}


################################################################################
# Create Security Group and Rules
################################################################################
resource "aws_security_group" "node_sg" {
  name        = "${var.name_prefix}-node-sg-${var.resource_tag}"
  description = "Security group for all Server nodes in the cluster"
  vpc_id      = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-server-sg-${var.resource_tag}" }
  )
}

resource "aws_security_group_rule" "server_node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node_sg.id
  source_security_group_id = aws_security_group.node_sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "server_node_ingress_ssh" {
  description       = "SSH for nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.node_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 22
  type              = "ingress"
}


################################################################################
# Create workload EC2 instances
################################################################################
resource "aws_instance" "server_host" {
  count                  = var.workload_count
  ami                    = data.aws_ssm_parameter.amazon_linux_latest.value
  instance_type          = var.instance_type
  key_name               = var.instance_key
  subnet_id              = element(var.subnet_id, count.index)
  iam_instance_profile   = aws_iam_instance_profile.server_host_profile.name
  vpc_security_group_ids = [aws_security_group.node_sg.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-server-node${count.index + 1}-${var.resource_tag}" }
  )
}
