output "storage_account_id" {
  value       = azurerm_storage_account.this.id
  description = "Resource ID of the storage account."
}

output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "Name of the storage account."
}

output "primary_connection_string" {
  value       = azurerm_storage_account.this.primary_connection_string
  description = "Primary connection string (sensitive)."
  sensitive   = true
}

output "primary_access_key" {
  value       = azurerm_storage_account.this.primary_access_key
  description = "Primary access key (sensitive)."
  sensitive   = true
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.this.primary_blob_endpoint
  description = "Primary blob endpoint."
}
