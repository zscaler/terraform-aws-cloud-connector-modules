variable "aws_region" {
  type        = string
  description = "The AWS region."
  default     = "us-east-1"
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

variable "az_count" {
  type        = number
  description = "Number of Availability Zones. Must match the number of IDs provided in byo_cc_subnet_ids, byo_tgw_attach_subnet_ids, byo_gwlb_endpoint_subnet_ids, byo_tgw_attach_rt_ids, and byo_gwlb_endpoint_rt_ids"
  default     = 2
  validation {
    condition = (
      var.az_count >= 1 && var.az_count <= 3
    )
    error_message = "Input az_count must be set to a single value between 1 and 3."
  }
}

variable "owner_tag" {
  type        = string
  description = "Populate custom owner tag attribute"
  default     = "zscc-admin"
}

variable "tls_key_algorithm" {
  type        = string
  description = "Algorithm for tls_private_key resource"
  default     = "RSA"
}

variable "cc_count" {
  type        = number
  description = "Default number of Cloud Connector appliances to create"
  default     = 2
}

variable "ccvm_instance_type" {
  type        = string
  description = "Cloud Connector Instance Type"
  default     = "m6i.large"
  validation {
    condition = (
      var.ccvm_instance_type == "t3.medium" ||
      var.ccvm_instance_type == "m5n.large" ||
      var.ccvm_instance_type == "c5a.large" ||
      var.ccvm_instance_type == "m6i.large" ||
      var.ccvm_instance_type == "c6i.large" ||
      var.ccvm_instance_type == "c6in.large" ||
      var.ccvm_instance_type == "m5n.4xlarge" ||
      var.ccvm_instance_type == "m6i.4xlarge" ||
      var.ccvm_instance_type == "c6i.4xlarge" ||
      var.ccvm_instance_type == "c6in.4xlarge"
    )
    error_message = "Input ccvm_instance_type must be set to an approved vm instance type."
  }
}

variable "cc_instance_size" {
  type        = string
  description = "Cloud Connector Instance size. Determined by and needs to match the Cloud Connector Portal provisioning template configuration"
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
  small_cc_instance  = ["t3.medium", "m5n.large", "c5a.large", "m6i.large", "c6i.large", "c6in.large", "m5n.4xlarge", "m6i.4xlarge", "c6i.4xlarge", "c6in.4xlarge"]
  medium_cc_instance = ["m5n.4xlarge", "m6i.4xlarge", "c6i.4xlarge", "c6in.4xlarge"]
  large_cc_instance  = ["m5n.4xlarge", "m6i.4xlarge", "c6i.4xlarge", "c6in.4xlarge"]

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

variable "reuse_security_group" {
  type        = bool
  description = "Specifies whether the SG module should create 1:1 security groups per instance or 1 security group for all instances"
  default     = false
}

variable "reuse_iam" {
  type        = bool
  description = "Specifies whether the IAM module should create 1:1 IAM per instance or 1 IAM for all instances"
  default     = false
}

variable "ami_id" {
  type        = list(string)
  description = "AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a replacement. It is also inputted as a list to facilitate if a customer desired to manually upgrade select CCs deployed based on the cc_count index"
  default     = [""]
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
  description = "The number of unsuccessful health checks required before a healthy target becomes unhealthy. Minimum 2 and maximum 10"
  default     = 3
}

variable "cross_zone_lb_enabled" {
  type        = bool
  description = "Determines whether GWLB cross zone load balancing should be enabled or not"
  default     = false
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

variable "mgmt_ssh_enabled" {
  type        = bool
  description = "Default is true which creates an ingress rule permitting SSH traffic from the local VPC to the CC management interface. If false, the rule is not created. Value ignored if not creating a security group"
  default     = true
}

variable "all_ports_egress_enabled" {
  type        = bool
  default     = true
  description = "Default is true which creates an egress rule permitting the CC service interface to forward direct traffic on all ports and protocols. If false, the rule is not created. Value ignored if not creating a security group"
}

variable "ebs_volume_type" {
  type        = string
  description = "(Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp3"
  default     = "gp3"
}

variable "ebs_encryption_enabled" {
  type        = bool
  description = "true/false whether to enable EBS encryption on the root volume. Default is true"
  default     = true
}

variable "byo_kms_key_alias" {
  type        = string
  description = "Requires var.ebs_encryption_enabled to be true. Set to null by default which is the AWS default managed/master key. Set as 'alias/<key-alias>' to use a custom KMS key"
  default     = null
}

variable "cloud_tags_enabled" {
  type        = bool
  description = "Determines whether or not to create the cc_tags_policy IAM Policy and attach it to the CC IAM Role"
  default     = false
}

variable "support_access_enabled" {
  type        = bool
  description = "If Network Security Group is being configured, enable a specific outbound rule for Cloud Connector to be able to establish connectivity for Zscaler support access. Default is true"
  default     = true
}

variable "zssupport_server" {
  type        = string
  description = "Destination IP address of Zscaler Support access server. IP resolution of remotesupport.<zscaler_customer_cloud>.net"
  default     = "199.168.148.101/32"
}

variable "hostname_type" {
  type        = string
  description = "Type of hostname for Amazon EC2 instances"
  default     = "resource-name"

  validation {
    condition = (
      var.hostname_type == "resource-name" ||
      var.hostname_type == "ip-name"
    )
    error_message = "Input hostname_type must be set to either resource-name or ip-name."
  }
}

variable "resource_name_dns_a_record_enabled" {
  type        = bool
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default is false"
  default     = false
}


################################################################################
# BYO (Bring-your-own) — IAM and Security Group
################################################################################

variable "byo_iam" {
  type        = bool
  description = "Bring your own IAM Instance Profile for Cloud Connector"
  default     = false
}

variable "byo_iam_instance_profile_id" {
  type        = list(string)
  description = "IAM Instance Profile ID for Cloud Connector association"
  default     = null
}

variable "byo_security_group" {
  type        = bool
  description = "Bring your own Security Group for Cloud Connector"
  default     = false
}

variable "byo_mgmt_security_group_id" {
  type        = list(string)
  description = "Management Security Group ID for Cloud Connector association"
  default     = null
}

variable "byo_service_security_group_id" {
  type        = list(string)
  description = "Service Security Group ID for Cloud Connector association"
  default     = null
}

variable "byo_endpoint_service_name" {
  type        = string
  description = "Existing GWLB Endpoint Service name to associate GWLB Endpoints to. Example string format: \"com.amazonaws.vpce.<region>.<service id>\""
  default     = null
}


################################################################################
# BYO (Bring-your-own) — Hub VPC Network Infrastructure
################################################################################

variable "byo_vpc_id" {
  type        = string
  description = "Existing Hub VPC ID where Cloud Connectors and GWLB will be deployed"
}

variable "byo_cc_subnet_ids" {
  type        = list(string)
  description = "Existing CC subnet IDs in the Hub VPC (one per AZ, ordered by AZ). Cloud Connector VMs and GWLB will be placed here. The associated route table must already have 0.0.0.0/0 → NAT Gateway for CC management egress to Zscaler"
}

variable "byo_tgw_attach_subnet_ids" {
  type        = list(string)
  description = "Existing TGW attachment subnet IDs in the Hub VPC (one per AZ, ordered by AZ). Terraform will add a 0.0.0.0/0 → GWLB Endpoint route to the route tables specified in byo_tgw_attach_rt_ids"
}

variable "byo_gwlb_endpoint_subnet_ids" {
  type        = list(string)
  description = "Existing GWLB endpoint subnet IDs in the Hub VPC (one per AZ, ordered by AZ). GWLB Endpoint ENIs will be placed here. Terraform will add spoke_vpc_cidrs → TGW routes to the route tables specified in byo_gwlb_endpoint_rt_ids"
}

variable "byo_tgw_attach_rt_ids" {
  type        = list(string)
  description = "Existing route table IDs associated with the TGW attach subnets (one per AZ, ordered by AZ). Terraform will inject 0.0.0.0/0 → GWLB Endpoint routes here"
}

variable "byo_gwlb_endpoint_rt_ids" {
  type        = list(string)
  description = "Existing route table IDs associated with the GWLB endpoint subnets (one per AZ, ordered by AZ). Terraform will inject spoke_vpc_cidrs → TGW routes here for east-west return traffic"
}


################################################################################
# BYO (Bring-your-own) — Transit Gateway
################################################################################

variable "byo_tgw_id" {
  type        = string
  description = "Existing Transit Gateway ID. Used for east-west return routing in GWLB endpoint subnet route tables"
}

variable "byo_hub_public_subnet_id" {
  type        = string
  description = "Existing public subnet ID in Hub VPC for the bastion host. Used for SSH jump access to Cloud Connector VMs during testing."
  default     = null
}

variable "bastion_nsg_source_prefix" {
  type        = list(string)
  description = "CIDR blocks permitted for SSH access to the Hub bastion. Default permits all."
  default     = ["0.0.0.0/0"]
}

variable "spoke_vpc_cidrs" {
  type        = list(string)
  description = "List of Spoke VPC CIDR blocks. A route will be added to each GWLB endpoint subnet route table for each CIDR, pointing to the Transit Gateway. Required for east-west traffic return path after CC inspection. Example: [\"10.1.0.0/16\", \"10.2.0.0/16\"]"
}
