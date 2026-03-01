# ═══════════════════════════════════════════════════════════════════════════
# Terraform Test: MSSQL Server and Database
# ═══════════════════════════════════════════════════════════════════════════
# Run with: terraform test

run "mssql_setup" {
  command = plan

  variables {
    resource_group_name           = "test-rg"
    location                      = "eastus"
    resource_prefix               = "test"
    administrator_login           = "sqladmin"
    administrator_login_password  = "P@ssw0rd123!"
    database_name                 = "testdb"
    tags = {
      Environment = "test"
      Project     = "mssql-blueprint"
    }
  }

  # Assertions
  assert {
    condition     = azurerm_mssql_server.this.administrator_login == "sqladmin"
    error_message = "SQL Server administrator login not set correctly."
  }

  assert {
    condition     = azurerm_mssql_database.this.name == "testdb"
    error_message = "Database name not set correctly."
  }

  assert {
    condition     = azurerm_mssql_database.this.sku_name == "S0"
    error_message = "Database SKU not set to default S0."
  }

  assert {
    condition     = azurerm_mssql_server.this.minimum_tls_version == "1.2"
    error_message = "Minimum TLS version not set correctly."
  }

  assert {
    condition     = azurerm_mssql_firewall_rule.allow_azure_services.id != null
    error_message = "Azure services firewall rule not created."
  }
}

run "mssql_with_custom_config" {
  command = plan

  variables {
    resource_group_name           = "test-rg"
    location                      = "westeurope"
    resource_prefix               = "prod"
    administrator_login           = "dba"
    administrator_login_password  = "C0mpl3x!P@ssw0rd"
    database_name                 = "proddb"
    sku_name                      = "S2"
    max_size_gb                   = 50
    backup_retention_days         = 30
    zone_redundant                = false
    allow_public_network_access   = false
    tags = {
      Environment = "production"
      Project     = "mssql-blueprint"
      Backup      = "critical"
    }
    allowed_ip_ranges = {
      "office" = {
        start_ip = "203.0.113.0"
        end_ip   = "203.0.113.255"
      }
      "vpn" = {
        start_ip = "198.51.100.0"
        end_ip   = "198.51.100.255"
      }
    }
  }

  # Assertions
  assert {
    condition     = azurerm_mssql_database.this.sku_name == "S2"
    error_message = "Database SKU not set to S2."
  }

  assert {
    condition     = azurerm_mssql_database.this.max_size_gb == 50
    error_message = "Database max size not set to 50 GB."
  }

  assert {
    condition     = azurerm_mssql_database.this.short_term_retention_policy[0].retention_days == 30
    error_message = "Backup retention not set to 30 days."
  }

  assert {
    condition     = azurerm_mssql_server.this.public_network_access_enabled == false
    error_message = "Public network access should be disabled."
  }

  assert {
    condition     = length(azurerm_mssql_firewall_rule.ip_ranges) == 2
    error_message = "Expected 2 custom firewall rules but got different count."
  }

  assert {
    condition     = contains(keys(azurerm_mssql_firewall_rule.ip_ranges), "office")
    error_message = "Office firewall rule not created."
  }

  assert {
    condition     = contains(keys(azurerm_mssql_firewall_rule.ip_ranges), "vpn")
    error_message = "VPN firewall rule not created."
  }
}

run "mssql_with_azure_ad" {
  command = plan

  variables {
    resource_group_name           = "test-rg"
    location                      = "eastus"
    resource_prefix               = "aad"
    administrator_login           = "sqladmin"
    administrator_login_password  = "P@ssw0rd123!"
    database_name                 = "aaddb"
    enable_azure_ad_admin         = true
    azure_ad_admin_login          = "dba-group"
    azure_ad_admin_object_id      = "12345678-1234-1234-1234-123456789012"
    azure_ad_only_authentication  = false
    enable_managed_identity       = true
    tags = {
      Environment = "production"
      Security    = "aad"
    }
  }

  assert {
    condition     = azurerm_mssql_server_active_directory_administrator.this[0].login_username == "dba-group"
    error_message = "Azure AD admin login not set correctly."
  }

  assert {
    condition     = azurerm_mssql_server.this.identity[0].type == "SystemAssigned"
    error_message = "Managed identity not enabled."
  }
}

run "mssql_validation_password" {
  command = plan

  variables {
    resource_group_name           = "test-rg"
    location                      = "eastus"
    resource_prefix               = "test"
    administrator_login           = "sqladmin"
    administrator_login_password  = "weak"  # Should fail validation
    database_name                 = "testdb"
  }

  # This should fail validation
  expect_failures = [
    var.administrator_login_password,
  ]
}

run "mssql_validation_db_name" {
  command = plan

  variables {
    resource_group_name           = "test-rg"
    location                      = "eastus"
    resource_prefix               = "test"
    administrator_login           = "sqladmin"
    administrator_login_password  = "P@ssw0rd123!"
    database_name                 = ""  # Should fail validation
  }

  # This should fail validation
  expect_failures = [
    var.database_name,
  ]
}
