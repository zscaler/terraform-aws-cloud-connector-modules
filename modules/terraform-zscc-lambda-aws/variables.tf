variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all Cloud Connector Lambda module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all Cloud Connector Lambda module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the Route 53 Endpoints"
}

variable "cc_vm1_id" {
  type        = string
  description = "Cloud Connector 1 instance id"
}

variable "cc_vm2_id" {
  type        = string
  description = "Cloud Connector 2 instance id"
}

variable "cc_subnet_ids" {
  type        = list(string)
  description = "List of Cloud Connector service subnet IDs"
}

variable "cc_vm1_rte_list" {
  type        = list(string)
  description = "List of route tables using Cloud Connector 1 instance id"
}

variable "cc_vm2_rte_list" {
  type        = list(string)
  description = "List of route tables using Cloud Connector 2 instance id"
}

variable "http_probe_port" {
  type        = number
  description = "HTTP port to send the health probes on Cloud Connector cloud"
  default     = 50000
  validation {
    condition = (
      var.http_probe_port == 80 ||
      (var.http_probe_port >= 1024 && var.http_probe_port <= 65535)
    )
    error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
  }
}

variable "route_updater_filename" {
  type        = string
  description = "Route updater lambda deployment package filename"
  default     = "rte_updater_lambda.py.zip"
}

variable "route_updater_handler" {
  type        = string
  description = "Route updater lambda handler"
  default     = "rte_updater_lambda.lambda_handler"
}

variable "route_updater_runtime" {
  type        = string
  description = "Route updater lambda runtime"
  default     = "python3.8"
}
