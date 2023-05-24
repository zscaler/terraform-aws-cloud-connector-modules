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

variable "workloads_enabled" {
  type        = bool
  default     = false
  description = "Configure Workload Subnets, Route Tables, and associations if set to true"
}


## GWLB specific variables
variable "gwlb_enabled" {
  type        = bool
  default     = true
  description = "Default is true. Workload/Route 53 subnet route tables will point to vpc_endpoint_id via var.gwlb_endpoint_ids input. If false, these Route Tables will point to network_interface_id via var.cc_service_enis"
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

variable "deregistration_delay" {
  type        = number
  description = "Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds."
  default     = 0
}

variable "rebalance_enabled" {
  type        = bool
  description = "Indicates how the GWLB handles existing flows when a target is deregistered or marked unhealthy. true means rebalance. false means no_rebalance. Default: true"
  default     = true
}

variable "ami_id" {
  type        = list(string)
  description = "AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a launch template change."
  default     = [""]
}

# ZPA/Route53 specific variables
variable "zpa_enabled" {
  type        = bool
  description = "Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection"
  default     = false
}

variable "domain_names" {
  type        = map(any)
  description = "Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars ZPA/Route 53 specific variables"
  default     = {}
}

variable "target_address" {
  type        = list(string)
  description = "Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses"
  default     = ["185.46.212.88", "185.46.212.89"]
}


# ASG specific variables
variable "min_size" {
  type        = number
  description = "Mininum number of Cloud Connectors to maintain in Autoscaling group"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maxinum number of Cloud Connectors to maintain in Autoscaling group"
  default     = 4
  validation {
    condition = (
      var.max_size >= 1 && var.max_size <= 10
    )
    error_message = "Input max_size must be set to a number between 1 and 10."
  }
}

variable "health_check_grace_period" {
  type        = number
  description = "The amount of time until EC2 Auto Scaling performs the first health check on new instances after they are put into service. With lifecycle hooks it is immediate. Otheriwse Default is 15 minutes"
  default     = 0
}

variable "warm_pool_enabled" {
  type        = bool
  description = "If set to true, add a warm pool to the specified Auto Scaling group. See [warm_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool)."
  default     = "false"
}

variable "warm_pool_state" {
  type        = string
  description = "Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm_pool_enabled' is false"
  default     = null
}

variable "warm_pool_min_size" {
  type        = number
  description = "Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm_pool_enabled' is false"
  default     = null
}

variable "warm_pool_max_group_prepared_capacity" {
  type        = number
  description = "Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm_pool_enabled' is false"
  default     = null
}

variable "reuse_on_scale_in" {
  type        = bool
  description = "Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in."
  default     = "false"
}

variable "launch_template_version" {
  type        = string
  description = "Launch template version. Can be version number, `$Latest` or `$Default`"
  default     = "$Latest"
}

variable "target_tracking_metric" {
  type        = string
  description = "The AWS ASG pre-defined target tracking metric type. Cloud Connector recommends ASGAverageCPUUtilization"
  default     = "ASGAverageCPUUtilization"
  validation {
    condition = (
      var.target_tracking_metric == "ASGAverageCPUUtilization" ||
      var.target_tracking_metric == "ASGAverageNetworkIn" ||
      var.target_tracking_metric == "ASGAverageNetworkOut"
    )
    error_message = "Input target_tracking_metric must be set to an approved predefined metric."
  }
}

variable "target_cpu_util_value" {
  type        = number
  description = "Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number"
  default     = 40
}

variable "lifecyclehook_instance_launch_wait_time" {
  type        = number
  description = "The maximum amount of time to wait in pending:wait state on instance launch in warmpool"
  default     = 1800
}

variable "lifecyclehook_instance_terminate_wait_time" {
  type        = number
  description = "The maximum amount of time to wait in terminating:wait state on instance termination"
  default     = 900
}

variable "asg_enabled" {
  type        = bool
  description = "Determines whether or not to create the cc_autoscale_lifecycle_policy IAM Policy and attach it to the CC IAM Role"
  default     = true
}

variable "sns_enabled" {
  type        = bool
  description = "Determine whether or not to create autoscaling group notifications. Default is false. If setting this value to true, terraform will also create a new sns topic and topic subscription"
  default     = false
}

variable "sns_email_list" {
  type        = list(string)
  description = "List of email addresses to input for sns topic subscriptions for autoscaling group notifications. Required if sns_enabled variable is true and byo_sns_topic false"
  default     = [""]
}

variable "byo_sns_topic" {
  type        = bool
  description = "Determine whether or not to create an AWS SNS topic and topic subscription for email alerts. Setting this variable to true implies you should also set variable sns_enabled to true"
  default     = false
}

variable "byo_sns_topic_name" {
  type        = string
  description = "Existing SNS Topic friendly name to be used for autoscaling group notifications"
  default     = ""
}

variable "protect_from_scale_in" {
  type        = bool
  description = "Whether newly launched instances are automatically protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection in the Amazon EC2 Auto Scaling User Guide"
  default     = false
}

variable "instance_warmup" {
  type        = number
  description = "Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data. Set this value equal to the amount of time that it takes for resource consumption to become stable after an instance reaches the InService state"
  default     = 0
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
