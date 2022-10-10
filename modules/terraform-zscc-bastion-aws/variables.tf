variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the bastion module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the bastion module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "Cloud Connector VPC ID"
}

variable "public_subnet" {
  type        = string
  description = "The public subnet where the bastion host has to be attached"
}

variable "instance_type" {
  type        = string
  description = "The bastion host EC2 instance type"
  default     = "t3.micro"
}

variable "disk_size" {
  type        = number
  description = "The size of the root volume in gigabytes."
  default     = 10
}

variable "bastion_nsg_source_prefix" {
  type        = list(string)
  description = "CIDR blocks of trusted networks for bastion host ssh access"
  default     = ["0.0.0.0/0"]
}

variable "instance_key" {
  type        = string
  description = "SSH Key for instances"
}

variable "iam_role_policy_ssmcore" {
  type        = string
  description = "AWS EC2 Instance predefined IAM Role to access AWS SSM"
  default     = "AmazonSSMManagedInstanceCore"
}
