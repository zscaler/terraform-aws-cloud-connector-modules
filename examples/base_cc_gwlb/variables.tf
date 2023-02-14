variable "aws_region" {
  type        = string
  description = "The AWS region."
  default     = "us-west-2"
}

variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zscc"
  validation {
    condition     = length(var.name_prefix) <= 12
    error_message = "Variable name_prefix must be 12 or less characters."
  }
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

variable "workload_count" {
  type        = number
  description = "Default number of workload VMs to create"
  default     = 2
}

variable "az_count" {
  type        = number
  description = "Default number of subnets to create based on availability zone"
  default     = 2
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

variable "cc_count" {
  type        = number
  description = "Default number of Cloud Connector appliances to create"
  default     = 4
}

variable "ccvm_instance_type" {
  type        = string
  description = "Cloud Connector Instance Type"
  default     = "m5.large"
  validation {
    condition = (
      var.ccvm_instance_type == "t3.medium" ||
      var.ccvm_instance_type == "m5.large" ||
      var.ccvm_instance_type == "c5.large" ||
      var.ccvm_instance_type == "c5a.large" ||
      var.ccvm_instance_type == "m5.2xlarge" ||
      var.ccvm_instance_type == "c5.2xlarge" ||
      var.ccvm_instance_type == "m5.4xlarge" ||
      var.ccvm_instance_type == "c5.4xlarge"
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
  small_cc_instance  = ["t3.medium", "m5.large", "c5.large", "c5a.large", "m5.2xlarge", "c5.2xlarge", "m5.4xlarge", "c5.4xlarge"]
  medium_cc_instance = ["m5.2xlarge", "c5.2xlarge", "m5.4xlarge", "c5.4xlarge"]
  large_cc_instance  = ["m5.4xlarge", "c5.4xlarge"]

  valid_cc_create = (
    contains(local.small_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "small" ||
    contains(local.medium_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "medium" ||
    contains(local.large_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "large"
  )
}

variable "cc_vm_prov_url" {
  type        = string
  description = "Zscaler Cloud Connector Provisioning URL"
}

variable "secret_name" {
  type        = string
  description = "AWS Secrets Manager Secret Name for Cloud Connector provisioning"
}

variable "http_probe_port" {
  type        = number
  description = "Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group"
  default     = 50000
  validation {
    condition = (
      tonumber(var.http_probe_port) == 80 ||
      (tonumber(var.http_probe_port) >= 1024 && tonumber(var.http_probe_port) <= 65535)
    )
    error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
  }
}

variable "cc_callhome_enabled" {
  type        = bool
  description = "determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role"
  default     = true
}

variable "reuse_security_group" {
  type        = bool
  description = "Specifies whether the SG module should create 1:1 security groups per instance or 1 security group for all instances"
  default     = false
}

variable "reuse_iam" {
  type        = bool
  description = "Specifies whether the SG module should create 1:1 IAM per instance or 1 IAM for all instances"
  default     = false
}

variable "health_check_interval" {
  type        = number
  description = "Interval for GWLB target group health check probing, in seconds, of Cloud Connector targets. Minimum 5 and maximum 300 seconds"
  default     = 10
}

variable "healthy_threshold" {
  type        = number
  description = "The number of successful health checks required before an unhealthy target becomes healthy. Minimum 2 and maximum 10"
  default     = 2
}

variable "unhealthy_threshold" {
  type        = number
  description = "The number of unsuccessful health checks required before an healthy target becomes unhealthy. Minimum 2 and maximum 10"
  default     = 3
}

variable "cross_zone_lb_enabled" {
  type        = bool
  description = "Determines whether GWLB cross zone load balancing should be enabled or not"
  default     = false
}

variable "gwlb_enabled" {
  type        = bool
  default     = true
  description = "Default is true. Workload/Route 53 subnet Route Tables will point to network_interface_id via var.cc_service_enis. If true, Route Tables will point to vpc_endpoint_id via var.gwlb_endpoint_ids input."
}

variable "acceptance_required" {
  type        = bool
  description = "Whether to require manual acceptance of any VPC Endpoint registration attempts to the Endpoint Service or not. Default is false"
  default     = false
}

variable "allowed_principals" {
  type        = list(string)
  description = "List of AWS Principal ARNs who are allowed access to the GWLB Endpoint Service. E.g. [\"arn:aws:iam::1234567890:root\"]`. See https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#accept-reject-connection-requests"
  default     = []
}
variable "deregistration_delay" {
  type        = number
  description = "Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds."
  default     = 0
}

variable "flow_stickiness" {
  type        = string
  description = "Options are (Default) 5-tuple (src ip/src port/dest ip/dest port/protocol), 3-tuple (src ip/dest ip/protocol), or 2-tuple (src ip/dest ip)"
  default     = "5-tuple"

  validation {
    condition = (
      var.flow_stickiness == "2-tuple" ||
      var.flow_stickiness == "3-tuple" ||
      var.flow_stickiness == "5-tuple"
    )
    error_message = "Input flow_stickiness must be set to an approved value of either 5-tuple, 3-tuple, or 2-tuple."
  }
}

variable "rebalance_enabled" {
  type        = bool
  description = "Indicates how the GWLB handles existing flows when a target is deregistered or marked unhealthy. true means rebalance. false means no_rebalance. Default: true"
  default     = true
}

variable "ami_id" {
  type        = list(string)
  description = "AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a replacement. It is also inputted as a list to facilitate if a customer desired to manually upgrade select CCs deployed based on the cc_count index"
  default     = [""]
}
