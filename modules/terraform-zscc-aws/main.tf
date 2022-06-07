data "aws_region" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc
}

resource "null_resource" "error-checker" {
  count = local.valid_cc_create ? 0 : 1 # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> ${path.root}/errorlog.txt
EOF
  }
}

# Locate current CC AMI by product code
data "aws_ami" "cloudconnector" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["2l8tfysndbav4tv2nfjwak3cu"]
  }

  owners = ["aws-marketplace"]
}


# Create IAM role and instance profile w/ SSM and Secrets Manager access policies

# Define AssumeRole access for EC2
data "aws_iam_policy_document" "instance-assume-role-policy" {
  version     = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Define AssumeRole access for CC callhome trust
data "aws_iam_policy_document" "cc-callhome-policy-document" {
  version     = "2012-10-17"
  statement {
    sid       = "AllowDelegationForCallhome"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::223544365242:role/callhome-delegation-role"]
  }
}

# Create IAM Policy for CC callhome
resource "aws_iam_policy" "cc-callhome-policy" {
  count       = local.valid_cc_create && var.cc_callhome_enabled ? var.cc_count : 0
  description = "Policy which allows STS AssumeRole when attached to a user or role. Used for CC callhome"
  name        = "${var.name_prefix}-cc-${count.index + 1}-callhome-policy-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc-callhome-policy-document.json
}

# Attach CC callhome policy to CC IAM Role
resource "aws_iam_role_policy_attachment" "cc-callhome-policy-attachment" {
  count = local.valid_cc_create && var.cc_callhome_enabled ? var.cc_count : 0
  policy_arn = aws_iam_policy.cc-callhome-policy.*.arn[count.index]
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]
}

# AWS Managed Secrets Manager Policy
resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite" {
  count = local.valid_cc_create ? var.cc_count : 0
  policy_arn = "arn:aws:iam::aws:policy/${var.iam_role_policy_smrw}"
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]
}

# AWS Managed SSM Manager Policy
resource "aws_iam_role_policy_attachment" "SSMManagedInstanceCore" {
  count = local.valid_cc_create ? var.cc_count : 0
  policy_arn = "arn:aws:iam::aws:policy/${var.iam_role_policy_ssmcore}"
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]
}

# Create CC IAM Role
resource "aws_iam_role" "cc-node-iam-role" {
  count = local.valid_cc_create ? var.cc_count : 0
  name = "${var.name_prefix}-cc-${count.index + 1}-node-iam-role-${var.resource_tag}"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

# Assign CC IAM Role to Instance Profile for CC instance attachment
resource "aws_iam_instance_profile" "cc-host-profile" {
  count      = local.valid_cc_create ? var.cc_count : 0
  name       = "${var.name_prefix}-cc-${count.index + 1}-host-profile-${var.resource_tag}"
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]
}


# Create Security Group for CC Management Interface
resource "aws_security_group" "cc-mgmt-sg" {
  count = local.valid_cc_create ? var.cc_count : 0
  name        = "${var.name_prefix}-cc-${count.index + 1}-mgmt-sg-${var.resource_tag}"
  description = "Security group for Cloud Connector-${count.index + 1} management interface"
  vpc_id      = var.vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-${count.index + 1}-mgmt-sg-${var.resource_tag}" }
  )
}

resource "aws_security_group_rule" "cc-mgmt-ingress-ssh" {
  count = local.valid_cc_create ? var.cc_count : 0
  description       = "Allow SSH to Cloud Connector VM"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.cc-mgmt-sg.*.id[count.index]
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  type              = "ingress"
}

# Create Security Group for Service Interface
resource "aws_security_group" "cc-service-sg" {
  count = local.valid_cc_create ? var.cc_count : 0
  name        = "${var.name_prefix}-cc-${count.index + 1}-svc-sg-${var.resource_tag}"
  description = "Security group for Cloud Connector-${count.index + 1} service interfaces"
  vpc_id      = var.vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-${count.index + 1}-svc-sg-${var.resource_tag}" }
  )
}

resource "aws_security_group_rule" "all-vpc-ingress-cc" {
  count = local.valid_cc_create ? var.cc_count : 0
  description       = "Allow all VPC traffic"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.cc-service-sg.*.id[count.index]
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}


# Create Cloud Connector VM
resource "aws_instance" "cc-vm" {
  count = local.valid_cc_create ? var.cc_count : 0
  ami                         = data.aws_ami.cloudconnector.id
  instance_type               = var.ccvm_instance_type
  iam_instance_profile        = aws_iam_instance_profile.cc-host-profile.*.name[count.index]
  vpc_security_group_ids      = [aws_security_group.cc-mgmt-sg.*.id[count.index]]
  subnet_id                   = element(var.mgmt_subnet_id, count.index)
  key_name                    = var.instance_key
  associate_public_ip_address = false
  user_data                   = base64encode(var.user_data)
  
  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}" }
  )
}

# Create Cloud Connector Service Interface for Small CC. This interface becomes LB0 interface for Medium/Large CC
resource "aws_network_interface" "cc-vm-nic-index-1" {
  count = local.valid_cc_create ? var.cc_count : 0
  description       = var.cc_instance_size == "small" ? "Primary Interface for service traffic" : "CC Med/Lrg LB interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [aws_security_group.cc-service-sg.*.id[count.index]]
  source_dest_check = false
  private_ips_count = 1
  attachment {
    instance        = aws_instance.cc-vm[count.index].id
    device_index    = 1
  }

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF1" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc-vm-nic-index-1-eni" {
  count = local.valid_cc_create ? var.cc_count : 0
  id = element(aws_network_interface.cc-vm-nic-index-1.*.id, count.index)
}


# Create Cloud Connector Service Interface #1 for Medium/Large CC. This resource will not be created for "small" CC instances
resource "aws_network_interface" "cc-vm-nic-index-2" {
  count             = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  description       = "CC Service 1 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [aws_security_group.cc-service-sg.*.id[count.index]]
  source_dest_check = false
  attachment {
    instance        = aws_instance.cc-vm[count.index].id
    device_index    = 2
  }

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF-2" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc-vm-nic-index-2-eni" {
  count = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  id    = element(aws_network_interface.cc-vm-nic-index-2.*.id, count.index)
}


# Create Cloud Connector Service Interface #2 for Medium/Large CC. This resource will not be created for "small" CC instances
resource "aws_network_interface" "cc-vm-nic-index-3" {
  count             = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  description       = "CC Service 2 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [aws_security_group.cc-service-sg.*.id[count.index]]
  source_dest_check = false
  attachment {
    instance        = aws_instance.cc-vm[count.index].id
    device_index    = 3
  }

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF-3" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc-vm-nic-index-3-eni" {
  count = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  id    = element(aws_network_interface.cc-vm-nic-index-3.*.id, count.index)
}


# Create Cloud Connector Service Interface #3 for Large CC. This resource will not be created for "small" or "medium" CC instances
resource "aws_network_interface" "cc-vm-nic-index-4" {
  count             = local.valid_cc_create && var.cc_instance_size == "large" ? var.cc_count : 0
  description       = "CC Service 3 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [aws_security_group.cc-service-sg.*.id[count.index]]
  source_dest_check = false
  attachment {
    instance        = aws_instance.cc-vm[count.index].id
    device_index    = 4
  }

  tags = merge(var.global_tags,
        { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF-4" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc-vm-nic-index-4-eni" {
  count = local.valid_cc_create && var.cc_instance_size == "large" ? var.cc_count : 0
  id = element(aws_network_interface.cc-vm-nic-index-4.*.id, count.index)
}