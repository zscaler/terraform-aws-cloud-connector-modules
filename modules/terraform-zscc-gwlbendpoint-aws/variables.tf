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
  default     = null
}

variable "cc_subnet_ids" {
  type        = list(string)
  description = "Cloud Connector subnet IDs list"
  default     = []
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = []
}

variable "gwlb_arn" {
  type = string
  description = "ARN of GWLB for Endpoint Service to be assigned"
  default = []
}