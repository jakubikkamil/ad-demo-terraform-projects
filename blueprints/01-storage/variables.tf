variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the storage account."
}

variable "location" {
  type        = string
  description = "Azure region for the storage account."
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
  description = "Optional override for storage account name. If empty, name is derived from prefix."
  default     = ""
}

variable "account_tier" {
  type        = string
  description = "Storage account tier: Standard or Premium."
  default     = "Standard"
}

variable "account_replication_type" {
  type        = string
  description = "Replication type: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  default     = "LRS"
}

variable "account_kind" {
  type        = string
  description = "Account kind: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  default     = "StorageV2"
}

variable "access_tier" {
  type        = string
  description = "Access tier for blob storage: Hot or Cool."
  default     = "Hot"
}

variable "allow_public_network_access" {
  type        = bool
  description = "Allow public network access (true for public storage)."
  default     = true
}
