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

variable "global_tags" {
  type        = map(any)
  description = "populate custom user provided tags"
}

variable "sg_count" {
  description = "Default number of security groups to create"
  default     = 1
}

variable "byo_security_group" {
  default     = false
  type        = bool
  description = "Bring your own Security Group for Cloud Connector"
}

variable "byo_mgmt_security_group_id" {
  type        = list(string)
  default     = null
  description = "Management Security Group ID for Cloud Connector association"
}

variable "byo_service_security_group_id" {
  type        = list(string)
  default     = null
  description = "Service Security Group ID for Cloud Connector association"
}
