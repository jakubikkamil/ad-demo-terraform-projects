locals {
  # Key Vault name: 3-24 chars, letters, numbers, hyphens; start with letter; no consecutive hyphens
  prefix_clean  = replace(lower(var.resource_prefix), "/[^a-z0-9]/", "")
  base_name     = var.name_override != "" ? replace(var.name_override, "/[^a-zA-Z0-9-]/", "") : "${prefix_clean}-kv"
  keyvault_name = substr("${local.base_name}${substr(md5("${var.resource_group_name}-${var.location}"), 0, 6)}", 0, 24)

  # Build role_assignments from permission lists (Key Vault RBAC)
  admin_assignments = {
    for i, pid in var.admins : "admin-${i}" => {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = pid
    }
  }
  reader_assignments = {
    for i, pid in var.readers : "reader-${i}" => {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = pid
    }
  }
  data_writer_assignments = {
    for i, pid in var.data_writers : "datawriter-${i}" => {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = pid
    }
  }
  data_reader_assignments = {
    for i, pid in var.data_readers : "datareader-${i}" => {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = pid
    }
  }
  role_assignments = merge(
    local.admin_assignments,
    local.reader_assignments,
    local.data_writer_assignments,
    local.data_reader_assignments
  )

  network_acls_input = length(var.network_acls) > 0 ? {
    bypass                     = try(var.network_acls.bypass, "AzureServices")
    default_action             = try(var.network_acls.default_action, "Allow")
    ip_rules                   = try(var.network_acls.ip_rules, [])
    virtual_network_subnet_ids = try(var.network_acls.virtual_network_subnet_ids, [])
  } : null
}

module "keyvault" {
  source = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 1.0"

  name                = local.keyvault_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  tenant_id            = var.tenant_id
  tags                 = var.tags
  role_assignments     = local.role_assignments
  network_acls         = local.network_acls_input
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled  = var.purge_protection_enabled
}
