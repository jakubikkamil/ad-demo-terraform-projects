# ═══════════════════════════════════════════════════════════════════════════
# Outputs for MSSQL Server and Database Blueprint
# ═══════════════════════════════════════════════════════════════════════════

# SQL Server Outputs
output "sql_server_id" {
  description = "The ID of the created SQL Server."
  value       = azurerm_mssql_server.this.id
}

output "sql_server_name" {
  description = "The name of the created SQL Server."
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL Server."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_server_admin_login" {
  description = "The administrator login name for the SQL Server."
  value       = azurerm_mssql_server.this.administrator_login
  sensitive   = true
}

output "sql_server_identity" {
  description = "The managed identity of the SQL Server (if enabled)."
  value       = try(azurerm_mssql_server.this.identity[0], null)
}

# SQL Database Outputs
output "sql_database_id" {
  description = "The ID of the created SQL Database."
  value       = azurerm_mssql_database.this.id
}

output "sql_database_name" {
  description = "The name of the created SQL Database."
  value       = azurerm_mssql_database.this.name
}

output "sql_database_server_id" {
  description = "The server ID of the created SQL Database."
  value       = azurerm_mssql_database.this.server_id
}

# Connection Strings
output "connection_string_sqlauth" {
  description = "SQL Server connection string using SQL authentication."
  value       = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.this.name};Persist Security Info=False;User ID=${azurerm_mssql_server.this.administrator_login};Password=YOUR_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

output "connection_string_template" {
  description = "SQL Server connection string template (replace YOUR_PASSWORD with actual password)."
  value       = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.this.name};Persist Security Info=False;User ID=${azurerm_mssql_server.this.administrator_login};Password=YOUR_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

# Connection Details for Applications
output "connection_details" {
  description = "Connection details for the SQL database."
  value = {
    server_fqdn       = azurerm_mssql_server.this.fully_qualified_domain_name
    server_name       = azurerm_mssql_server.this.name
    database_name     = azurerm_mssql_database.this.name
    admin_login       = azurerm_mssql_server.this.administrator_login
    port              = 1433
  }
}

# Firewall Rules
output "firewall_rules" {
  description = "Created firewall rules for the SQL Server."
  value = {
    for rule in concat(
      [azurerm_mssql_firewall_rule.allow_azure_services],
      values(azurerm_mssql_firewall_rule.ip_ranges)
    ) : rule.name => {
      id              = rule.id
      start_ip_address = rule.start_ip_address
      end_ip_address   = rule.end_ip_address
    }
  }
}

# Database SKU and Configuration
output "database_configuration" {
  description = "Database configuration details."
  value = {
    sku_name      = azurerm_mssql_database.this.sku_name
    max_size_gb   = azurerm_mssql_database.this.max_size_gb
    collation     = azurerm_mssql_database.this.collation
    zone_redundant = azurerm_mssql_database.this.zone_redundant
    create_mode   = azurerm_mssql_database.this.create_mode
  }
}

# Backup Configuration
output "backup_configuration" {
  description = "Backup and retention configuration."
  value = {
    short_term_retention_days  = azurerm_mssql_database.this.short_term_retention_policy[0].retention_days
    backup_interval_hours      = azurerm_mssql_database.this.short_term_retention_policy[0].backup_interval_in_hours
    long_term_retention_enabled = var.enable_long_term_retention
    weekly_retention           = var.long_term_retention_weekly
    monthly_retention          = var.long_term_retention_monthly
    yearly_retention           = var.long_term_retention_yearly
  }
}


# Management Portal Links
output "management_links" {
  description = "Links to Azure portal for management."
  value = {
    sql_server_portal  = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_mssql_server.this.id}"
    database_portal    = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_mssql_database.this.id}"
  }
}

# Data source for current context
data "azurerm_client_config" "current" {}
