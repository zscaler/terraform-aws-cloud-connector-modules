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

variable "vpc_id" {
  type        = string
  description = "Cloud Connector VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnet ID to create GLWB Endpoints in"
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "gwlb_arn" {
  type        = string
  description = "ARN of GWLB for Endpoint Service to be assigned"
}