# Test 01-storage: public storage account plan (no apply, no Azure credentials required for plan-only)

provider "azurerm" {
  features {}
}

variables {
  resource_group_name = "test-rg-storage"
  location            = "centralpoland"
  resource_prefix     = "test"
  tags = {
    Environment = "test"
    Project     = "blueprint-test"
  }
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  allow_public_network_access = true
}

run "storage_account_planned" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.account_tier == "Standard"
    error_message = "account_tier should be Standard"
  }

  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "LRS"
    error_message = "account_replication_type should be LRS"
  }

  assert {
    condition     = azurerm_storage_account.this.account_kind == "StorageV2"
    error_message = "account_kind should be StorageV2"
  }

  assert {
    condition     = azurerm_storage_account.this.public_network_access_enabled == true
    error_message = "public storage should have public_network_access_enabled true"
  }

  assert {
    condition     = length(azurerm_storage_account.this.name) >= 3 && length(azurerm_storage_account.this.name) <= 24
    error_message = "storage account name must be 3-24 characters"
  }

  assert {
    condition     = can(regex("^[a-z0-9]+$", azurerm_storage_account.this.name))
    error_message = "storage account name must be lowercase alphanumeric only"
  }
}

run "storage_outputs" {
  command = plan

  assert {
    condition     = output.storage_account_name == azurerm_storage_account.this.name
    error_message = "output storage_account_name should match resource name"
  }
}
