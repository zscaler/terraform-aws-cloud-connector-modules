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
  type        = map(any)
  description = "Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars step 10"
}

variable "target_address" {
  type        = list(string)
  description = "Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses"
  default     = ["185.46.212.88", "185.46.212.89"]
}

variable "zscaler_domains" {
  type        = map(any)
  description = "Domains that Route 53 should not forward to Cloud Connector"

  default = {
    ZS-FreeBSD      = "freebsd.org"
    ZS-NTP          = "ntp.org"
    ZS-Zscaler      = "zscaler.com"
    ZS-Zpath        = "zpath.net"
    ZS-ZPAGov       = "zpagov.net"
    ZS-ZPABeta      = "zpabeta.net"
    ZS-ZscalerBeta  = "zscalerbeta.net"
    ZS-ZsNet        = "zscaler.net"
    ZS-ZscalerOne   = "zscalerone.net"
    ZS-ZscalerTwo   = "zscalertwo.net"
    ZS-ZscalerThree = "zscalerthree.net"
    ZS-ZsCloud      = "zscloud.net"
    ZS-ZscalerGov   = "zscalergov.net"
  }
}
