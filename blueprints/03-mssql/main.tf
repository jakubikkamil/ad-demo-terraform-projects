# ═══════════════════════════════════════════════════════════════════════════
# Azure SQL Server and Database Blueprint
# ═══════════════════════════════════════════════════════════════════════════
# This blueprint creates:
# - SQL Server with Azure AD admin and firewall rules
# - SQL Database with backup and retention policies
# - Private endpoint (optional)
# - Auditing policies (optional)
#
# Usage:
#   module "mssql" {
#     source = "./blueprints/03-mssql"
#     
#     resource_group_name      = azurerm_resource_group.this.name
#     location                 = azurerm_resource_group.this.location
#     resource_prefix          = "myapp"
#     tags                     = { Environment = "prod" }
#     
#     # Server configuration
#     administrator_login       = "sqladmin"
#     # password should come from Azure Key Vault in production
#     
#     # Database configuration
#     database_name            = "appdb"
#     sku_name                 = "S1"  # Standard tier
#   }
# ═══════════════════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════
# Random Administrator Credentials
# ═══════════════════════════════════════════════════════════════════════════


# Naming convention for SQL Server
locals {
  prefix_clean   = replace(lower(var.resource_prefix), "/[^a-z0-9]/", "")
  base_name      = var.name_override != "" ? lower(replace(var.name_override, "/[^a-z0-9]/", "")) : "${local.prefix_clean}sql"
  # SQL Server names: 3-63 chars, lowercase alphanumeric and hyphens
  sql_server_name = substr("${local.base_name}-${substr(md5("${var.resource_group_name}-${var.location}"), 0, 8)}", 0, 63)
}


# Generate random administrator login
resource "random_string" "sql_admin_login" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Generate random administrator password
resource "random_password" "sql_admin_password" {
  length            = 32
  special           = true
  override_special  = "!@#$%^&*()_+-=[]{}?:,./<>|"
  min_upper         = 4
  min_lower         = 4
  min_numeric       = 4
  min_special       = 4
}

# Store login in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_login" {
  name         = "${local.base_name}-admin-login"
  value        = random_string.sql_admin_login.result
  key_vault_id = var.key_vault_id

  depends_on = [random_string.sql_admin_login]
}

# Store password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "${local.base_name}-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = var.key_vault_id

  depends_on = [random_password.sql_admin_password]
}

# Azure SQL Server
resource "azurerm_mssql_server" "this" {
  name                         = local.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.server_version
  administrator_login          = random_string.sql_admin_login.result
  administrator_login_password = random_password.sql_admin_password.result

  # Minimum TLS version
  minimum_tls_version = var.minimum_tls_version

  # Identity for server-managed features (optional)
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Public network access
  public_network_access_enabled = var.allow_public_network_access

  tags = var.tags

  depends_on = []
}

# SQL Server Firewall Rule - Allow Azure Services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# SQL Server Firewall Rules - Additional IP ranges
resource "azurerm_mssql_firewall_rule" "ip_ranges" {
  for_each = var.allowed_ip_ranges

  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

# SQL Database
resource "azurerm_mssql_database" "this" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.this.id
  collation      = var.database_collation
  max_size_gb    = var.max_size_gb
  sku_name       = var.sku_name
  zone_redundant = var.zone_redundant

  # Backup retention
  short_term_retention_policy {
    retention_days           = var.backup_retention_days
    backup_interval_in_hours = 24
  }

  # Long-term retention (if enabled)
  dynamic "long_term_retention_policy" {
    for_each = var.enable_long_term_retention ? [1] : []
    content {
      weekly_retention  = var.long_term_retention_weekly
      monthly_retention = var.long_term_retention_monthly
      yearly_retention  = var.long_term_retention_yearly
      week_of_year      = var.long_term_retention_week_of_year
    }
  }


  tags = var.tags

  depends_on = [azurerm_mssql_server.this]
}




