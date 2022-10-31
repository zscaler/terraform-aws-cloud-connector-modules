################################################################################
# Pull VPC information
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
# Create pre-defined AWS Security Groups and rules for Bastion
################################################################################
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg-${var.resource_tag}"
  description = "Allow SSH access to bastion host and outbound internet access"
  vpc_id      = data.aws_vpc.selected.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-bastion-sg-${var.resource_tag}" }
  )
}

resource "aws_security_group_rule" "ssh" {
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = var.bastion_nsg_source_prefix
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "internet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "intranet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.bastion.id
}


################################################################################
# Define AssumeRole access for EC2
################################################################################
data "aws_iam_policy_document" "bastion_instance_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


################################################################################
# Create Bastion IAM Role and Host/Instance Profile
################################################################################
resource "aws_iam_role" "bastion_iam_role" {
  name               = "${var.name_prefix}-bastion-iam-role-${var.resource_tag}"
  assume_role_policy = data.aws_iam_policy_document.bastion_instance_assume_role_policy.json

  tags = merge(var.global_tags)
}


################################################################################
# Define AWS Managed SSM Manager Policy
################################################################################
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/${var.iam_role_policy_ssmcore}"
  role       = aws_iam_role.bastion_iam_role.name
}


################################################################################
# Assign IAM Role to Instance Profile for Bastion instance attachment
################################################################################
resource "aws_iam_instance_profile" "bastion_host_profile" {
  name = "${var.name_prefix}-bastion-host-profile-${var.resource_tag}"
  role = aws_iam_role.bastion_iam_role.name

  tags = merge(var.global_tags)
}


################################################################################
# Create Bastion EC2 host with automatic public IP association
################################################################################
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.amazon_linux_latest.value
  instance_type               = var.instance_type
  key_name                    = var.instance_key
  subnet_id                   = var.public_subnet
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_host_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.disk_size
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-bastion-host-${var.resource_tag}" }
  )
}
