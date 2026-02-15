# Test 02-keyvault: Key Vault module plan (no apply; Azure provider may need credentials for plan)

provider "azurerm" {
  features {}
}

variables {
  resource_group_name = "test-rg-kv"
  location            = "centralpoland"
  resource_prefix     = "test"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  tags = {
    Environment = "test"
    Project     = "blueprint-test"
  }
  admins                    = []
  readers                   = []
  data_writers              = []
  data_readers              = []
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  network_acls               = {}
}

run "keyvault_planned" {
  command = plan

  assert {
    condition     = length(module.keyvault.name) >= 3 && length(module.keyvault.name) <= 24
    error_message = "Key Vault name must be 3-24 characters"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9-]+$", module.keyvault.name))
    error_message = "Key Vault name must be alphanumeric and hyphens only"
  }
}

run "keyvault_outputs" {
  command = plan

  assert {
    condition     = output.key_vault_name == module.keyvault.name
    error_message = "output key_vault_name should match module name"
  }

  # Name is known at plan time; id and uri are only known after apply
  assert {
    condition     = length(output.key_vault_name) >= 3 && length(output.key_vault_name) <= 24
    error_message = "key_vault_name output should be valid length"
  }
}
