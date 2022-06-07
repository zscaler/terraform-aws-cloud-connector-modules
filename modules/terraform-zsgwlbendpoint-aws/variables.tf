variable "name_prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource_tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "Cloud Connector VPC"
}

variable "cc_subnet_ids" {
  description = "Cloud Connector subnet IDs list"
}

variable "global_tags" {
  description = "populate custom user provided tags"
}

variable "gwlb_arn" {
  description = "ARN of GWLB for Endpoint Service to be assigned"
}