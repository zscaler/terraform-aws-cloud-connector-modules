variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the network module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the network module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IP CIDR Range. All subnet resources that might get created (public, workload, cloud connector) are derived from this /16 CIDR. If you require creating a VPC smaller than /16, you may need to explicitly define all other subnets via public_subnets, workload_subnets, cc_subnets, and route53_subnets variables"
  default     = "10.1.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public/NAT GW Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc_cidr variable."
  default     = null
}

variable "workloads_subnets" {
  type        = list(string)
  description = "Workload Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc_cidr variable."
  default     = null
}

variable "cc_subnets" {
  type        = list(string)
  description = "Cloud Connector Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc_cidr variable."
  default     = null
}

variable "route53_subnets" {
  type        = list(string)
  description = "Route 53 Outbound Endpoint Subnets to create in VPC. This is only required if you want to override the default subnets that this code creates via vpc_cidr variable."
  default     = null
}

variable "zpa_enabled" {
  type        = bool
  default     = false
  description = "Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection"
}

variable "workloads_enabled" {
  type        = bool
  default     = false
  description = "Configure Workload Subnets, Route Tables, and associations if set to true"
}

variable "gwlb_enabled" {
  type        = bool
  default     = false
  description = "Default is false. Workload/Route 53 subnet Route Tables will point to network_interface_id via var.cc_service_enis. If true, Route Tables will point to vpc_endpoint_id via var.gwlb_endpoint_ids input."
}

variable "gwlb_endpoint_ids" {
  type        = list(string)
  default     = [""]
  description = "List of GWLB Endpoint IDs for use in private workload and/or Route 53 subnet route tables with GWLB deployments. Utilized if var.gwlb_enabled is set to true"
}

variable "cc_service_enis" {
  type        = list(string)
  default     = [""]
  description = "List of Cloud Connector Service ENIs for use in private workload and/or Route 53 subnet route tables with HA/non-GWLB deployments. Utilized if var.gwlb_enabled is set to false"
}

variable "az_count" {
  type        = number
  description = "Default number of subnets to create based on availability zone input"
  default     = 2
  validation {
    condition = (
      (var.az_count >= 1 && var.az_count <= 3)
    )
    error_message = "Input az_count must be set to a single value between 1 and 3. Note* some regions have greater than 3 AZs. Please modify az_count validation in variables.tf if you are utilizing more than 3 AZs in a region that supports it. https://aws.amazon.com/about-aws/global-infrastructure/regions_az/."
  }
}

variable "base_only" {
  type        = bool
  default     = false
  description = "Default is falase. Only applicable for base deployment type resulting in workload and bastion hosts, but no Cloud Connector resources. Setting this to true will point workload route able to nat_gateway_id"
}

# BYO (Bring-your-own) variables list

variable "byo_vpc" {
  type        = bool
  description = "Bring your own AWS VPC for Cloud Connector"
  default     = false
}

variable "byo_vpc_id" {
  type        = string
  description = "User provided existing AWS VPC ID"
  default     = null
}

variable "byo_subnets" {
  type        = bool
  description = "Bring your own AWS Subnets for Cloud Connector"
  default     = false
}

variable "byo_subnet_ids" {
  type        = list(string)
  description = "User provided existing AWS Subnet IDs"
  default     = null
}

variable "byo_igw" {
  type        = bool
  description = "Bring your own AWS VPC for Cloud Connector"
  default     = false
}

variable "byo_igw_id" {
  type        = string
  description = "User provided existing AWS Internet Gateway ID"
  default     = null
}

variable "byo_ngw" {
  type        = bool
  description = "Bring your own AWS NAT Gateway(s) Cloud Connector"
  default     = false
}

variable "byo_ngw_ids" {
  type        = list(string)
  description = "User provided existing AWS NAT Gateway IDs"
  default     = null
}
