# -----------------------------------------------------------------------------
# modules/gateway — Zscaler Managed ZTGW (Native ZTC Provider)
#
# Interacts with the Zscaler OneAPI / Connector Gateway via the official
# ztc_zero_trust_gateway Terraform provider resource across GCP and AWS.
# -----------------------------------------------------------------------------

locals {
  platform      = upper(var.platform)
  location_name = var.location_name != null ? var.location_name : "Unified-${local.platform}-${var.region}"
}

resource "ztc_zero_trust_gateway" "this" {
  name                  = var.gateway_name
  platform              = local.platform
  region                = var.region
  availability_zone_ids = var.availability_zones
  location_name         = local.location_name
  allowlist_projects    = var.allowlist_projects
  auto_activate_pending = var.auto_activate_pending
}
