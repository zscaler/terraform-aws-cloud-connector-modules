variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all Route 53 module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all Route 53 module resources"
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

variable "r53_subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs for the Route53 Endpoint"
}

variable "domain_names" {
  type        = map(map(string))
  description = "Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars step 10"
  default = {
    appseg01 = { domain_name = "example.com" }
  }
}

variable "target_address" {
  type        = list(string)
  description = "Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses"
  default     = ["185.46.212.88", "185.46.212.89"]
}

variable "zscaler_domains" {
  type        = map(map(string))
  description = "Domains that Route 53 should not forward to Cloud Connector"

  default = {
    ZS-FreeBSD      = { domain_name = "freebsd.org" }
    ZS-NTP          = { domain_name = "ntp.org" }
    ZS-Zscaler      = { domain_name = "zscaler.com" }
    ZS-Zpath        = { domain_name = "zpath.net" }
    ZS-ZPAGov       = { domain_name = "zpagov.net" }
    ZS-ZPABeta      = { domain_name = "zpabeta.net" }
    ZS-ZscalerBeta  = { domain_name = "zscalerbeta.net" }
    ZS-ZsNet        = { domain_name = "zscaler.net" }
    ZS-ZscalerOne   = { domain_name = "zscalerone.net" }
    ZS-ZscalerTwo   = { domain_name = "zscalertwo.net" }
    ZS-ZscalerThree = { domain_name = "zscalerthree.net" }
    ZS-ZsCloud      = { domain_name = "zscloud.net" }
    ZS-ZscalerGov   = { domain_name = "zscalergov.net" }
  }
}
