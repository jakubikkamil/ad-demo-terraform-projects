data "azurerm_client_config" "current" {}

# ── 00-init: shared defaults ─────────────────────────────────────────────────

module "init" {
  source = "../../../blueprints/00-init"

  tags            = var.config.init.tags
  resource_prefix = var.config.init.resource_prefix
  location        = var.config.init.location
  admins          = var.config.init.admins
  readers         = var.config.init.readers
  data_writers    = var.config.init.data_writers
  data_readers    = var.config.init.data_readers
}

# ── 01-storage: storage account ──────────────────────────────────────────────

module "storage" {
  for_each = var.config.storages != null ? var.config.storages : {} # Create one instance per storage config, or skip if null

  source = "../../../blueprints/01-storage"

  resource_group_name      = module.init.resource_group_name
  location                 = module.init.location
  resource_prefix          = module.init.resource_prefix
  tags                     = module.init.tags
  name_override            = each.value.name_override
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  account_kind             = each.value.account_kind
  access_tier              = each.value.access_tier
  allow_public_network_access = each.value.allow_public_network_access

  depends_on = [module.init] # Ensure init module runs first to create resource group
}

# ── 02-keyvault: key vault ───────────────────────────────────────────────────

module "keyvault" {
  for_each = var.config.keyvaults != null ? var.config.keyvaults : {} # Create one instance per keyvault config, or skip if null

  source = "../../../blueprints/02-keyvault"

  resource_group_name        = module.init.resource_group_name
  location                   = module.init.location
  resource_prefix            = module.init.resource_prefix
  tags                       = module.init.tags
  name_override              = each.value.name_override
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admins                     = module.init.admins
  readers                    = module.init.readers
  data_writers               = module.init.data_writers
  data_readers               = module.init.data_readers
  soft_delete_retention_days = each.value.soft_delete_retention_days
  purge_protection_enabled   = each.value.purge_protection_enabled
  network_acls               = each.value.network_acls

  depends_on = [module.init] # Ensure init module runs first to create resource group
}


# ── 03-mssql: mssql server ─────────────────────────────────────────────────────

module "mssql" {
  for_each = var.config.mssql_servers != null ? var.config.mssql_servers : {} # Create one instance per mssql config, or skip if null

  source = "../../../blueprints/03-mssql"

  resource_group_name      = module.init.resource_group_name
  location                 = module.init.location
  resource_prefix          = module.init.resource_prefix
  tags                     = module.init.tags

  key_vault_id                  = module.keyvault[keys(module.keyvault)[0]].key_vault_id
  database_name                 = each.value.database_name
  sku_name                      = each.value.sku_name
  backup_retention_days         = each.value.backup_retention_days

  depends_on = [module.init] # Ensure init module runs first to create resource group
}