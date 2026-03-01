variable "config" {
  description = "Full project configuration. Pass as a single JSON tfvars file."
  type = object({

    # ─────────────────────────────────────────────────────────────────────────
    # init: shared defaults consumed by all modules via module.init outputs
    # ─────────────────────────────────────────────────────────────────────────
    init = object({
      tags            = object({ Environment = string, Project = string, ManagedBy = optional(string, "terraform") }) # Tags propagated to every resource
      resource_prefix = optional(string, "addemo")     # Short prefix used to generate all resource names. If not provided, convert Project name from tags to lowercase and remove non-alphanumeric characters (e.g. "ad-demo" → "addemo")
      location        = optional(string, "centralpoland") # Azure region for all resources
      #User needs to have at least Reader role on the subscription to use this module, but for better experience it's recommended to have Owner or User Access Administrator role to avoid permission issues when assigning roles to created resources. If the user doesn't have sufficient permissions, they can provide an existing object ID with admin permissions (e.g. Key Vault Administrator) in the "admins" list below.
      admins          = list(string), # Object IDs granted admin permissions (e.g. Key Vault Administrator)
      readers         = optional(list(string), [])   # Object IDs granted read-only permissions
      data_writers    = optional(list(string), [])   # Object IDs granted data-plane write permissions
      data_readers    = optional(list(string), [])   # Object IDs granted data-plane read permissions
    })
    
    # ─────────────────────────────────────────────────────────────────────────
    # storage: Azure Storage Account (blueprint 01-storage)
    # ─────────────────────────────────────────────────────────────────────────
    storages = optional(map(object({
      name_override               = optional(string, "")          # Custom storage account name; auto-generated from prefix when empty
      account_tier                = optional(string, "Standard")  # Performance tier: Standard or Premium
      account_replication_type    = optional(string, "LRS")       # Redundancy: LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS
      account_kind                = optional(string, "StorageV2") # Account kind: BlobStorage | BlockBlobStorage | FileStorage | Storage | StorageV2
      access_tier                 = string                        # Blob access tier: Hot or Cool
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


    mssql_servers = optional(map(object({
      name_override                  = optional(string, "")           # Custom SQL Server name; auto-generated from prefix when empty
      administrator_login            = string                         # SQL Server admin username (e.g. "sqladmin")
      administrator_login_password   = string                         # SQL Server admin password (must meet complexity requirements)
      database_name                  = string                         # Initial database name to create (e.g. "maindb")
      sku_name                       = string                         # Pricing tier: S0, S1, S2, S3 (Standard); P1, P2, P3 (Premium); GP_Gen5_2, GP_Gen5_4, GP_Gen5_8 (General Purpose); BC_Gen5_2, BC_Gen5_4, BC_Gen5_8 (Business Critical)
      backup_retention_days          = optional(number, 7)            # Backup retention period in days (7–35 for Basic, 7–35 for Standard, 7–35 for Premium)
    })), null)

  })
}
