################################################################################
# Module VM creation validation
################################################################################
resource "null_resource" "error_checker" {
  count = local.valid_cc_create ? 0 : 1 # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> ${path.root}/errorlog.txt
EOF
  }
}

# Collect current region name for AMI selection
data "aws_region" "current" {}

/*
################################################################################
# Locate Latest CC AMI by product code
################################################################################
data "aws_ami" "cloudconnector" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["2l8tfysndbav4tv2nfjwak3cu"]
  }

  owners = ["aws-marketplace"]
}
*/

################################################################################
# Retrieve the default AWS KMS key in the current region for EBS encryption
################################################################################
data "aws_ebs_default_kms_key" "current_kms_key" {
  count = var.encrypted_ebs_enabled ? 1 : 0
}

################################################################################
# Retrieve an alias for the KMS key for EBS encryption
################################################################################
data "aws_kms_alias" "current_kms_arn" {
  count = var.encrypted_ebs_enabled ? 1 : 0
  name  = data.aws_ebs_default_kms_key.current_kms_key[0].key_arn
}


################################################################################
# Create Cloud Connector VM
################################################################################
resource "aws_instance" "cc_vm" {
  count                       = local.valid_cc_create ? var.cc_count : 0
  ami                         = var.private_amis[data.aws_region.current.name]
  instance_type               = var.ccvm_instance_type
  iam_instance_profile        = element(var.iam_instance_profile, count.index)
  vpc_security_group_ids      = [element(var.mgmt_security_group_id, count.index)]
  subnet_id                   = element(var.mgmt_subnet_id, count.index)
  key_name                    = var.instance_key
  associate_public_ip_address = false
  user_data                   = base64encode(var.user_data)

  ebs_optimized = true

  root_block_device {
    delete_on_termination = true
    encrypted             = var.encrypted_ebs_enabled
    kms_key_id            = var.encrypted_ebs_enabled ? data.aws_kms_alias.current_kms_arn[0].target_key_arn : null
    volume_type           = var.ebs_volume_type
    tags = merge(var.global_tags,
      { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-ebs-${var.resource_tag}" }
    )
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = var.imdsv2_enabled ? "required" : "optional"
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}" }
  )
}


################################################################################
# Create Cloud Connector Service Interface for Small CC. 
# This interface becomes LB0 interface for Medium/Large size CCs
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_1" {
  count             = local.valid_cc_create ? var.cc_count : 0
  description       = var.cc_instance_size == "small" ? "Primary Interface for service traffic" : "CC Med/Lrg LB interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  private_ips_count = 1
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 1
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF1" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc_vm_nic_index_1_eni" {
  count = local.valid_cc_create ? var.cc_count : 0
  id    = element(aws_network_interface.cc_vm_nic_index_1[*].id, count.index)
}


################################################################################
# Create Cloud Connector Service Interface #1 for Medium/Large CC. 
# This resource will not be created for "small" CC instances.
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_2" {
  count             = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  description       = "CC Service 1 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 2
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF-2" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc_vm_nic_index_2_eni" {
  count = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  id    = element(aws_network_interface.cc_vm_nic_index_2[*].id, count.index)
}


################################################################################
# Create Cloud Connector Service Interface #2 for Medium/Large CC. 
# This resource will not be created for "small" CC instances.
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_3" {
  count             = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  description       = "CC Service 2 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 3
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF-3" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc_vm_nic_index_3_eni" {
  count = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  id    = element(aws_network_interface.cc_vm_nic_index_3[*].id, count.index)
}


################################################################################
# Create Cloud Connector Service Interface #3 for Large CC. This resource will 
# not be created for "small" or "medium" CC instances
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_4" {
  count             = local.valid_cc_create && var.cc_instance_size == "large" ? var.cc_count : 0
  description       = "CC Service 3 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 4
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF-4" }
  )
}

# Get Data info of NIC to be able to output private IP values
data "aws_network_interface" "cc_vm_nic_index_4_eni" {
  count = local.valid_cc_create && var.cc_instance_size == "large" ? var.cc_count : 0
  id    = element(aws_network_interface.cc_vm_nic_index_4[*].id, count.index)
}
