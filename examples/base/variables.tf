variable "aws_region" {
  type        = string
  description = "The AWS region."
  default     = "us-west-2"
}

variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zsdemo"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.1.0.0/16"
}

variable "workload_count" {
  type        = number
  description = "Default number of workload VMs to create"
  default     = 1
}

variable "az_count" {
  type        = number
  description = "Default number of subnets to create based on availability zone"
  default     = 1
  validation {
    condition = (
      (var.az_count >= 1 && var.az_count <= 3)
    )
    error_message = "Input az_count must be set to a single value between 1 and 3. Note* some regions have greater than 3 AZs. Please modify az_count validation in variables.tf if you are utilizing more than 3 AZs in a region that supports it. https://aws.amazon.com/about-aws/global-infrastructure/regions_az/."
  }
}

variable "owner_tag" {
  type        = string
  description = "populate custom owner tag attribute"
  default     = "zscc-admin"
}

variable "tls_key_algorithm" {
  type        = string
  description = "algorithm for tls_private_key resource"
  default     = "RSA"
}

variable "bastion_nsg_source_prefix" {
  type        = list(string)
  description = "CIDR blocks of trusted networks for bastion host ssh access"
  default     = ["0.0.0.0/0"]
}

variable "zpa_enabled" {
  type        = bool
  default     = false
  description = "Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Default is false. If true, Cloud Connector Route Tables will route directly to selected IGW instead of NAT Gateway"
}