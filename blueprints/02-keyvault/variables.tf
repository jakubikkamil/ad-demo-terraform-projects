variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the Key Vault."
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for resource names (from init module)."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply (from init module)."
  default     = {}
}

variable "name_override" {
  type        = string
  description = "Optional override for Key Vault name. If empty, name is derived from prefix."
  default     = ""
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID (e.g. from azurerm_client_config)."
}

variable "admins" {
  type        = list(string)
  description = "Principal IDs with Key Vault admin permissions (from init module)."
  default     = []
}

variable "readers" {
  type        = list(string)
  description = "Principal IDs with read-only permissions (from init module)."
  default     = []
}

variable "data_writers" {
  type        = list(string)
  description = "Principal IDs with data write permissions (from init module)."
  default     = []
}

variable "data_readers" {
  type        = list(string)
  description = "Principal IDs with data read permissions (from init module)."
  default     = []
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Soft delete retention in days (7-90)."
  default     = 7
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Enable purge protection."
  default     = false
}

variable "network_acls" {
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action             = optional(string, "Allow")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  description = "Network ACLs for the Key Vault."
  default     = {}
}
