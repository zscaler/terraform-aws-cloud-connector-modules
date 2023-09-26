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

variable "gwlb_enabled" {
  type        = bool
  description = "Default is true which creates ingress/egress rules only for GENEVE traffic. If false, these rules are replaced with an allow all ports/protocols ingress. Value ignored if not creating a security group"
  default     = true
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
