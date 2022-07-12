data "aws_region" "current" {}
data "aws_vpc" "selected" {
  id = var.vpc
}

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }

  owners = ["aws-marketplace"]
}

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
  cidr_blocks       = var.allowed_hosts_from_bastion
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
  protocol  = "-1"
  from_port = 0
  to_port   = 0
  type      = "egress"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.centos.id
  instance_type               = var.instance_type
  key_name                    = var.instance_key
  subnet_id                   = var.public_subnet
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.disk_size
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-bastion-host-${var.resource_tag}" }
  )
}