variable "name_prefix" {
  description = "A prefix to associate to all the module resources"
  default     = "zscaler-cc"
}

variable "resource_tag" {
  description = "A tag to associate to all the module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "Main VPC"
}

variable "public_subnet" {
  description = "The public subnet where the bastion host has to be attached"
}

variable "instance_type" {
  description = "The type of instance for bastion host"
  default     = "t3.micro"
}

variable "disk_size" {
  description = "The size of the root volume in gigabytes."
  default     = 10
}

variable "allowed_hosts_from_bastion" {
  description = "CIDR blocks of trusted networks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_key" {
  description = "SSH Key for instances"
}

variable "global_tags" {
  description = "populate custom user provided tags"
}