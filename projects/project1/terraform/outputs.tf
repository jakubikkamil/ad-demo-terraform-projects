# ── Init ────────────────────────────────────────────────────────────────────

output "location" {
  value       = module.init.location
  description = "Azure region used for all resources."
}

output "resource_prefix" {
  value       = module.init.resource_prefix
  description = "Resource naming prefix."
}

output "tags" {
  value       = module.init.tags
  description = "Tags applied to all resources."
}

# ── Storage ──────────────────────────────────────────────────────────────────

output "storage_account_id" {
  value       = {for k, v in module.storage : k => v.storage_account_id}
  description = "Resource ID of the storage account."
}

output "storage_account_name" {
  value       = {for k, v in module.storage : k => v.storage_account_name}
  description = "Name of the storage account."
}

output "primary_blob_endpoint" {
  value       = {for k, v in module.storage : k => v.primary_blob_endpoint}
  description = "Primary blob service endpoint."
}

# ── Key Vault ────────────────────────────────────────────────────────────────

output "key_vault_id" {
  value       = {for k, v in module.keyvault : k => v.key_vault_id}
  description = "Resource ID of the Key Vault."
}

output "key_vault_name" {
  value       = {for k, v in module.keyvault : k => v.key_vault_name}
  description = "Name of the Key Vault."
}

output "key_vault_uri" {
  value       = {for k, v in module.keyvault : k => v.key_vault_uri}
  description = "URI of the Key Vault."
}
