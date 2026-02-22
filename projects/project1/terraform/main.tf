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
  source = "../../../blueprints/01-storage"

  resource_group_name      = module.init.resource_group_name
  location                 = module.init.location
  resource_prefix          = module.init.resource_prefix
  tags                     = module.init.tags
  name_override            = var.config.storage.name_override
  account_tier             = var.config.storage.account_tier
  account_replication_type = var.config.storage.account_replication_type
  account_kind             = var.config.storage.account_kind
  access_tier              = var.config.storage.access_tier
  allow_public_network_access = var.config.storage.allow_public_network_access

  depends_on = [module.init] # Ensure init module runs first to create resource group
}

# ── 02-keyvault: key vault ───────────────────────────────────────────────────

module "keyvault" {
  source = "../../../blueprints/02-keyvault"

  resource_group_name        = module.init.resource_group_name
  location                   = module.init.location
  resource_prefix            = module.init.resource_prefix
  tags                       = module.init.tags
  name_override              = var.config.keyvault.name_override
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admins                     = module.init.admins
  readers                    = module.init.readers
  data_writers               = module.init.data_writers
  data_readers               = module.init.data_readers
  soft_delete_retention_days = var.config.keyvault.soft_delete_retention_days
  purge_protection_enabled   = var.config.keyvault.purge_protection_enabled
  network_acls               = var.config.keyvault.network_acls

  depends_on = [module.init] # Ensure init module runs first to create resource group
}
