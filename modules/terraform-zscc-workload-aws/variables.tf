variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Workload module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Workload module resources"
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

variable "subnet_id" {
  type        = list(string)
  description = "List of private subnet IDs where workload servers will be deployed"
}

variable "instance_type" {
  type        = string
  description = "The workload server EC2 instance type"
  default     = "t3.micro"
}

variable "instance_key" {
  type        = string
  description = "SSH Key for instances"
}

variable "workload_count" {
  type        = number
  description = "number of workloads to deploy"
  default     = 1
}

variable "iam_role_policy_ssmcore" {
  type        = string
  description = "AWS EC2 Instance predefined IAM Role to access AWS SSM"
  default     = "AmazonSSMManagedInstanceCore"
}
