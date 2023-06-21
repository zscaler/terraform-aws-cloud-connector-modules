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
# Create Cloud Connector VM
################################################################################
resource "aws_instance" "cc_vm" {
  count                       = local.valid_cc_create ? var.cc_count : 0
  ami                         = element(var.ami_id, count.index)
  instance_type               = var.ccvm_instance_type
  iam_instance_profile        = element(var.iam_instance_profile, count.index)
  vpc_security_group_ids      = [element(var.mgmt_security_group_id, count.index)]
  subnet_id                   = element(var.mgmt_subnet_id, count.index)
  key_name                    = var.instance_key
  associate_public_ip_address = false
  user_data                   = base64encode(var.user_data)

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
