output "key_vault_id" {
  value       = module.keyvault.resource_id
  description = "Resource ID of the Key Vault."
}

output "key_vault_name" {
  value       = module.keyvault.name
  description = "Name of the Key Vault."
}

output "key_vault_uri" {
  value       = module.keyvault.uri
  description = "URI of the Key Vault."
}
