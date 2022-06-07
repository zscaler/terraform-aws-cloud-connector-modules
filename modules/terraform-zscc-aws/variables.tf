variable "name_prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource_tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "Cloud Connector VPC"
}

variable "iam_role_policy_smrw" {
  description = "Cloud Connector EC2 Instance IAM Role"
  default     = "SecretsManagerReadWrite"
}

variable "iam_role_policy_ssmcore" {
  description = "Cloud Connector EC2 Instance IAM Role"
  default     = "AmazonSSMManagedInstanceCore"
}

variable "mgmt_subnet_id" {
  description = "Cloud Connector EC2 Instance management subnet id"
}

variable "service_subnet_id" {
  description = "Cloud Connector EC2 Instance service subnet id"
}

variable "instance_key" {
  description = "Cloud Connector Instance Key"
}

variable "user_data" {
  description = "Cloud Init data"
}

variable "ccvm_instance_type" {
  description = "Cloud Connector Instance Type"
  default     = "m5.large"
  validation {
          condition     = ( 
            var.ccvm_instance_type == "t3.medium"  ||
            var.ccvm_instance_type == "m5.large"   ||
            var.ccvm_instance_type == "c5.large"   ||
            var.ccvm_instance_type == "c5a.large"  ||
            var.ccvm_instance_type == "m5.2xlarge" ||
            var.ccvm_instance_type == "c5.2xlarge" ||
            var.ccvm_instance_type == "m5.4xlarge" ||
            var.ccvm_instance_type == "c5.4xlarge"
          )
          error_message = "Input ccvm_instance_type must be set to an approved vm instance type."
      }
}


locals {
  small_cc_instance  = ["t3.medium","m5.large","c5.large","c5a.large","m5.2xlarge","c5.2xlarge","m5.4xlarge","c5.4xlarge"]
  medium_cc_instance = ["m5.2xlarge","c5.2xlarge","m5.4xlarge","c5.4xlarge"]
  large_cc_instance  = ["m5.4xlarge","c5.4xlarge"]
  
  valid_cc_create = (
contains(local.small_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "small"   ||
contains(local.medium_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "medium" ||
contains(local.large_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "large"
 )
}

variable "global_tags" {
  description = "populate custom user provided tags"
}

variable "cc_count" {
  description = "Default number of Cloud Connector appliances to create"
  default = 1
}

variable "cc_instance_size" {
  default = "small"
   validation {
          condition     = ( 
            var.cc_instance_size == "small"  ||
            var.cc_instance_size == "medium" ||
            var.cc_instance_size == "large"
          )
          error_message = "Input cc_instance_size must be set to an approved cc instance type."
      }
}

variable "cc_callhome_enabled" {
  description = "determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role"
  default = "true"
  type  = bool
}