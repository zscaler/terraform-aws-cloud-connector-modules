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

variable "cc_subnet_ids" {
  type        = list(string)
  description = "Cloud Connector EC2 Instance subnet IDs list"
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
      var.ccvm_instance_type == "t3a.medium" ||
      var.ccvm_instance_type == "m5n.large" ||
      var.ccvm_instance_type == "c5a.large" ||
      var.ccvm_instance_type == "m6i.large" ||
      var.ccvm_instance_type == "c6i.large" ||
      var.ccvm_instance_type == "c5.4xlarge" ||
      var.ccvm_instance_type == "m5n.4xlarge" ||
      var.ccvm_instance_type == "m6i.4xlarge" ||
      var.ccvm_instance_type == "c6i.4xlarge"
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
      var.cc_instance_size == "small"
    )
    error_message = "Input cc_instance_size must be set to an approved cc instance type."
  }
}

# Validation to ensure that ccvm_instance_type and cc_instance_size are set appropriately
locals {
  small_cc_instance  = ["t3.medium", "t3a.medium", "m5n.large", "c5a.large", "m6i.large", "c6i.large", "c5.4xlarge", "m5n.4xlarge", "m6i.4xlarge", "c6i.4xlarge"]
  medium_cc_instance = ["c5.4xlarge", "m5n.4xlarge", "m6i.4xlarge", "c6i.4xlarge"]
  large_cc_instance  = ["c5.4xlarge", "m5n.4xlarge", "m6i.4xlarge", "c6i.4xlarge"]

  valid_cc_create = (
    contains(local.small_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "small" ||
    contains(local.medium_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "medium" ||
    contains(local.large_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "large"
  )
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

variable "target_group_arn" {
  type        = string
  description = "ARN of GWLB Target Group for cloud connectors to be registered"
}

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

variable "instance_warmup" {
  type        = number
  description = "Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data. Set this value equal to the amount of time that it takes for resource consumption to become stable after an instance reaches the InService state"
  default     = 0
}

variable "health_check_type" {
  type        = string
  description = "EC2 or ELB. Controls how health checking is done"
  default     = "EC2"
  validation {
    condition = (
      var.health_check_type == "EC2" ||
      var.health_check_type == "ELB"
    )
    error_message = "Input health_check_type must be set to an approved predefined metric."
  }
}

variable "warm_pool_enabled" {
  type        = bool
  description = "If set to true, add a warm pool to the specified Auto Scaling group. See [warm_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#warm_pool)."
  default     = false
}

variable "warm_pool_state" {
  type        = string
  description = "Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running. Ignored when 'warm_pool_enabled' is false"
  default     = "Stopped"
}

variable "warm_pool_min_size" {
  type        = number
  description = "Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Ignored when 'warm_pool_enabled' is false"
  default     = 0
}

variable "warm_pool_max_group_prepared_capacity" {
  type        = number
  description = "Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. Ignored when 'warm_pool_enabled' is false"
  default     = null
}

variable "reuse_on_scale_in" {
  type        = bool
  description = "Specifies whether instances in the Auto Scaling group can be returned to the warm pool on scale in."
  default     = false
}

variable "launch_template_version" {
  type        = string
  description = "Launch template version. Can be version number, `$Latest` or `$Default`"
  default     = "$Latest"
}

variable "target_cpu_util_value" {
  type        = number
  description = "Target value number for autoscaling policy CPU utilization target tracking. ie: trigger a scale in/out to keep average CPU Utliization percentage across all instances at/under this number"
  default     = 80
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
  description = " Whether newly launched instances are automatically protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection in the Amazon EC2 Auto Scaling User Guide"
  default     = false
}

variable "ami_id" {
  type        = list(string)
  description = "AMI ID(s) to be used for deploying Cloud Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a launch template change."
}

variable "wait_for_capacity_timeout" {
  type        = string
  description = "Maximum duration that Terraform should wait for ASG instances to be healthy before timing out"
  default     = "0"
}

variable "imdsv2_enabled" {
  type        = bool
  description = "true/false whether to force IMDSv2 only for instance bring up. Default is true"
  default     = true
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
