variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "mgmt_subnet_id" {
  type        = list(string)
  description = "Cloud Connector EC2 Instance management subnet id"
}

variable "service_subnet_id" {
  type        = list(string)
  description = "Cloud Connector EC2 Instance service subnet id"
}

variable "instance_key" {
  type        = string
  description = "SSH Key for instances"
}

variable "user_data" {
  type        = string
  description = "Cloud Init data"
}

variable "ccvm_instance_type" {
  type        = string
  description = "Cloud Connector Instance Type"
  default     = "m6i.large"
  validation {
    condition = (
      var.ccvm_instance_type == "t3.medium" ||
      var.ccvm_instance_type == "m5n.large" ||
      var.ccvm_instance_type == "m5a.large" ||
      var.ccvm_instance_type == "c5a.large" ||
      var.ccvm_instance_type == "m6i.large" ||
      var.ccvm_instance_type == "m6a.large" ||
      var.ccvm_instance_type == "c6i.large" ||
      var.ccvm_instance_type == "c6a.large" ||
      var.ccvm_instance_type == "m5n.4xlarge" ||
      var.ccvm_instance_type == "m5a.4xlarge" ||
      var.ccvm_instance_type == "c5a.4xlarge" ||
      var.ccvm_instance_type == "m6i.4xlarge" ||
      var.ccvm_instance_type == "m6a.4xlarge" ||
      var.ccvm_instance_type == "c6i.4xlarge" ||
      var.ccvm_instance_type == "c6a.4xlarge"
    )
    error_message = "Input ccvm_instance_type must be set to an approved vm instance type."
  }
}

variable "cc_instance_size" {
  type        = string
  description = "Cloud Connector Instance size. Determined by and needs to match  the Cloud Connector Portal provisioning template configuration"
  default     = "small"
  validation {
    condition = (
      var.cc_instance_size == "small" ||
      var.cc_instance_size == "medium" ||
      var.cc_instance_size == "large"
    )
    error_message = "Input cc_instance_size must be set to an approved cc instance type."
  }
}

# Validation to ensure that ccvm_instance_type and cc_instance_size are set appropriately
locals {
  small_cc_instance  = ["t3.medium", "m5n.large", "m5a.large", "c5a.large", "m6i.large", "m6a.large", "c6i.large", "c6a.large", "m5n.4xlarge", "m5a.4xlarge", "c5a.4xlarge", "m6i.4xlarge", "m6a.4xlarge", "c6i.4xlarge", "c6a.4xlarge"]
  medium_cc_instance = ["m5n.4xlarge", "m5a.4xlarge", "c5a.4xlarge", "m6i.4xlarge", "m6a.4xlarge", "c6i.4xlarge", "c6a.4xlarge"]
  large_cc_instance  = ["m5n.4xlarge", "m5a.4xlarge", "c5a.4xlarge", "m6i.4xlarge", "m6a.4xlarge", "c6i.4xlarge", "c6a.4xlarge"]

  valid_cc_create = (
    contains(local.small_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "small" ||
    contains(local.medium_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "medium" ||
    contains(local.large_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "large"
  )
}

variable "cc_count" {
  type        = number
  description = "Default number of Cloud Connector appliances to create"
  default     = 1
}

variable "mgmt_security_group_id" {
  type        = list(string)
  description = "Cloud Connector EC2 Instance management subnet id"
}

variable "service_security_group_id" {
  type        = list(string)
  description = "Cloud Connector EC2 Instance service subnet id"
}

variable "iam_instance_profile" {
  type        = list(string)
  description = "IAM instance profile ID assigned to Cloud Connector"
}

variable "ami_id" {
  type        = list(string)
  description = "AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a replacement. It is also inputted as a list to facilitate if a customer desired to manually upgrade select CCs deployed based on the cc_count index"
}

variable "imdsv2_enabled" {
  type        = bool
  description = "true/false whether to force IMDSv2 only for instance bring up. Default is true"
  default     = true
}
