resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  # Public storage: allow public network access; no restrictive network_rules
  public_network_access_enabled = var.allow_public_network_access

  # Default to Allow so traffic is not restricted (public storage)
  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = var.tags
}

locals {
  # Storage account names: 3-24 chars, lowercase alphanumeric only
  prefix_clean = replace(lower(var.resource_prefix), "/[^a-z0-9]/", "")
  base_name    = var.name_override != "" ? lower(replace(var.name_override, "/[^a-z0-9]/", "")) : "${prefix_clean}st"
  storage_account_name = substr("${local.base_name}${substr(md5("${var.resource_group_name}-${var.location}"), 0, 8)}", 0, 24)
}
