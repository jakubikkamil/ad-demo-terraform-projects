variable "config" {
  description = "Full project configuration. Pass as a single JSON tfvars file."
  type = object({

    # ─────────────────────────────────────────────────────────────────────────
    # init: shared defaults consumed by all modules via module.init outputs
    # ─────────────────────────────────────────────────────────────────────────
    init = optional(object({
      tags            = optional(map(string), { Environment = "dev", Project = "ad-demo", ManagedBy = "terraform" }) # Tags propagated to every resource
      resource_prefix = optional(string, "addemo")     # Short prefix used to generate all resource names
      location        = optional(string, "westeurope") # Azure region for all resources
      admins          = optional(list(string), [])     # Object IDs granted admin permissions (e.g. Key Vault Administrator)
      readers         = optional(list(string), [])     # Object IDs granted read-only permissions
      data_writers    = optional(list(string), [])     # Object IDs granted data-plane write permissions
      data_readers    = optional(list(string), [])     # Object IDs granted data-plane read permissions
    }), {})
    
    # ─────────────────────────────────────────────────────────────────────────
    # storage: Azure Storage Account (blueprint 01-storage)
    # ─────────────────────────────────────────────────────────────────────────
    storages = optional(map(object({
      name_override               = optional(string, "")          # Custom storage account name; auto-generated from prefix when empty
      account_tier                = optional(string, "Standard")  # Performance tier: Standard or Premium
      account_replication_type    = optional(string, "LRS")       # Redundancy: LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS
      account_kind                = optional(string, "StorageV2") # Account kind: BlobStorage | BlockBlobStorage | FileStorage | Storage | StorageV2
      access_tier                 = optional(string, "Hot")       # Blob access tier: Hot or Cool
      allow_public_network_access = optional(bool, true)          # Set false to restrict access to private endpoints or VNet rules only
    })), null)

    # ─────────────────────────────────────────────────────────────────────────
    # keyvault: Azure Key Vault (blueprint 02-keyvault)
    # ─────────────────────────────────────────────────────────────────────────
    keyvaults = optional(map(object({
      name_override              = optional(string, "")   # Custom Key Vault name; auto-generated from prefix when empty
      soft_delete_retention_days = optional(number, 7)   # Days to retain soft-deleted secrets/keys/certs (7–90)
      purge_protection_enabled   = optional(bool, false) # Prevents permanent deletion until retention period expires
      network_acls = optional(object({
        bypass                     = optional(string, "AzureServices") # Services allowed to bypass network ACLs (e.g. AzureServices)
        default_action             = optional(string, "Allow")         # Default rule when no IP/VNet rule matches: Allow or Deny
        ip_rules                   = optional(list(string), [])        # Allowed IPv4 addresses or CIDR ranges
        virtual_network_subnet_ids = optional(list(string), [])        # Allowed subnet resource IDs
      }), {})
    })), null)

  })
}