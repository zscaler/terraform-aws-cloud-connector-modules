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


################################################################################
# Retrieve the default AWS KMS key in the current region for EBS encryption
################################################################################
data "aws_ebs_default_kms_key" "current_kms_key" {
  count = var.ebs_encryption_enabled ? 1 : 0
}

################################################################################
# Retrieve an alias for the KMS key for EBS encryption
################################################################################
data "aws_kms_alias" "current_kms_arn" {
  count = var.ebs_encryption_enabled ? 1 : 0
  name  = coalesce(var.byo_kms_key_alias, data.aws_ebs_default_kms_key.current_kms_key[0].key_arn)
}


################################################################################
# Create Cloud Connector VM
################################################################################
resource "aws_instance" "cc_vm" {
  count                = local.valid_cc_create ? var.cc_count : 0
  ami                  = element(var.ami_id, count.index)
  instance_type        = var.ccvm_instance_type
  iam_instance_profile = element(var.iam_instance_profile, count.index)
  key_name             = var.instance_key
  user_data            = base64encode(var.user_data)
  ebs_optimized        = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = var.imdsv2_enabled ? "required" : "optional"
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.cc_vm_nic_index_0[count.index].id
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = var.ebs_encryption_enabled
    kms_key_id            = var.ebs_encryption_enabled ? data.aws_kms_alias.current_kms_arn[0].target_key_arn : null
    volume_type           = var.ebs_volume_type
    tags = merge(var.global_tags,
      { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-ebs-${var.resource_tag}" }
    )
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record = var.resource_name_dns_a_record_enabled
    hostname_type                     = var.hostname_type
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}" }
  )

  lifecycle {
    ignore_changes = [private_dns_name_options]
    #While AWS supports changing hostname_type for deployed instances if stopped first, Cloud Connector does not. 
    #Whatever hostname_type value set at deployment will persist the lifetime of the EC2
    #If you do want to change this, you must destroy and redeploy the instance(s).
  }
}


################################################################################
# Create Cloud Connector Service Interface for "small" CC instances. 
# This interface becomes the Load Balancer VIP interface for "medium" and 
# "large" CC instances.
#
# This primary IP Address of this interface will be used for GWLB Target Group
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_0" {
  count             = local.valid_cc_create ? var.cc_count : 0
  description       = "cc next hop forwarding interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false

  tags = merge(var.global_tags,
  { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-FwdIF" })
}


################################################################################
# Create Cloud Connector Management Interface 
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_1" {
  count             = local.valid_cc_create ? var.cc_count : 0
  description       = "cc management interface"
  subnet_id         = element(var.mgmt_subnet_id, count.index)
  security_groups   = concat([element(var.mgmt_security_group_id, count.index)], var.additional_mgmt_security_group_ids)
  source_dest_check = true

  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 1
  }

  tags = merge(var.global_tags,
  { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-MgmtIF" })
}


################################################################################
# Create Cloud Connector Service Interface #1 for "medium" and "large" CC instances. 
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_2" {
  count             = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  description       = "cc service 1 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 2
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF1" }
  )
}


################################################################################
# Create Cloud Connector Service Interface #2 for "medium" and "large" CC instances. 
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_3" {
  count             = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  description       = "cc service 2 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 3
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF2" }
  )
}


################################################################################
# Create Cloud Connector Service Interface #3 for "large" CC instances. 
# This interface becomes the LB interface for "medium" CC instances.
# This resource will not be created for "small" CC instances.
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_4" {
  count             = local.valid_cc_create && var.cc_instance_size != "small" ? var.cc_count : 0
  description       = var.cc_instance_size == "medium" ? "cc lb interface" : "cc service 3 interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 4
  }

  tags = merge(var.global_tags,
    { Name = var.cc_instance_size == "medium" ? "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-LB" : "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF3" }
  )
}


################################################################################
# Create Cloud Connector LB Interface for "large" CC instances. 
# This resource will not be created for "small" or "medium" CC instances.
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_5" {
  count             = local.valid_cc_create && var.cc_instance_size == "large" ? var.cc_count : 0
  description       = "cc lb interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 5
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-LB" }
  )
}
