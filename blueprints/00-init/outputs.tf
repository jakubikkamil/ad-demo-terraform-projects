output "tags" {
  value       = var.tags
  description = "Default tags for inherited modules."
}

output "resource_prefix" {
  value       = local.resource_prefix
  description = "Resource naming prefix for inherited modules."
}

output "resource_group_name" {
  value       = local.resource_group_name
  description = "Resource group name for inherited modules."
}

output "location" {
  value       = var.location
  description = "Azure location for inherited modules."
}

output "admins" {
  value       = var.admins
  description = "Principal IDs with admin permissions."
}

output "readers" {
  value       = var.readers
  description = "Principal IDs with read-only permissions."
}

output "data_writers" {
  value       = var.data_writers
  description = "Principal IDs with data write permissions."
}

output "data_readers" {
  value       = var.data_readers
  description = "Principal IDs with data read permissions."
}
