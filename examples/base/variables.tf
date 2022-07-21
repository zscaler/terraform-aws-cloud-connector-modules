# aws variables

variable "aws_region" {
  description = "The AWS region."
  default     = "us-west-2"
}

variable "name_prefix" {
  description = "The name prefix for all your resources"
  default     = "zsdemo"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "10.1.0.0/16"
}

variable "workload_count" {
  description = "Default number of workload VMs to create"
  default     = 1
}

variable "az_count" {
  description = "Default number of subnets to create based on availability zone"
  type        = number
  default     = 1
  validation {
    condition = (
      (var.az_count >= 1 && var.az_count <= 3)
    )
    error_message = "Input az_count must be set to a single value between 1 and 3. Note* some regions have greater than 3 AZs. Please modify az_count validation in variables.tf if you are utilizing more than 3 AZs in a region that supports it. https://aws.amazon.com/about-aws/global-infrastructure/regions_az/."
  }
}

variable "owner_tag" {
  description = "populate custom owner tag attribute"
  type        = string
  default     = "zscc-admin"
}

variable "tls_key_algorithm" {
  default = "RSA"
  type    = string
}

variable "bastion_nsg_source_prefix" {
  description = "CIDR blocks of trusted networks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}