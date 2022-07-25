variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Cloud Connector Security Group module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Cloud Connector Security Group module resources"
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

variable "sg_count" {
  type        = number
  description = "Default number of security groups to create"
  default     = 1
}

variable "byo_security_group" {
  type        = bool
  description = "Bring your own Security Group for Cloud Connector. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo_mgmt_security_group_id and byo_service_security_group_id"
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
