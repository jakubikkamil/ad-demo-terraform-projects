variable "config" {
  description = "Full project configuration. Pass as a single JSON tfvars file."
  type = object({

    # ─────────────────────────────────────────────────────────────────────────
    # init: shared defaults consumed by all modules via module.init outputs
    # ─────────────────────────────────────────────────────────────────────────
    init = object({
      tags            = object({ Environment = string, Project = string, ManagedBy = optional(string, "terraform") }) # USER NEEDS TO PROVIDE REQUIRED TAGS. Environment and Project tags are required for resource naming and organization. ENVIRONMENT shoiuld have only 3 letters (e.g. "dev", "uat", "prd"). ManagedBy tag is optional and defaults to "terraform".
      resource_prefix = string,    # DO NOT ASK USER. CREATE IT FROM PROJECT NAME with maximum 8 character long. Short prefix used to generate all resource names. If not provided, convert Project name from tags to lowercase and remove non-alphanumeric characters (e.g. "ad-demo" → "addemo")
      location        = optional(string, "polandcentral") # DO NOT ASK USER FOR THAT. Azure region for all resources. 
      #User needs to have at least Reader role on the subscription to use this module, but for better experience it's recommended to have Owner or User Access Administrator role to avoid permission issues when assigning roles to created resources. If the user doesn't have sufficient permissions, they can provide an existing object ID with admin permissions (e.g. Key Vault Administrator) in the "admins" list below.
      admins          = list(string), # REQUIRED. NEEDS TO BE VALID FORMAT. Object IDs granted admin permissions. The Azure format of object ID e.g. "f7856123-6546-428d-b1a0-901fac478f8a" Example Azure Object ID (UUID v4 format). Number of characters should be 36 (including hyphens). Format also should match regex pattern: /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/
      readers         = optional(list(string)), # ASK but not Required. NEEDS TO BE VALID FORMAT. Object IDs granted admin permissions. The Azure format of object ID e.g. "f7856123-6546-428d-b1a0-901fac478f8a" Example Azure Object ID (UUID v4 format). Number of characters should be 36 (including hyphens). Format also should match regex pattern: /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/
      data_writers    = optional(list(string), [])   # ASK but not Required. Object IDs granted data-plane write permissions. The Azure format of object ID e.g. "f7856123-6546-428d-b1a0-901fac478f8a" Example Azure Object ID (UUID v4 format).  Number of characters should be 36 (including hyphens). Format also should match regex pattern: /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/
      data_readers    = optional(list(string), [])   # ASK but not Required. Object IDs granted data-plane read permissions. The Azure format of object ID e.g. "f7856123-6546-428d-b1a0-901fac478f8a" Example Azure Object ID (UUID v4 format).  Number of characters should be 36 (including hyphens). Format also should match regex pattern: /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/
    })
    
    # Azure RESOURCE CONFIGURATION
    # ─────────────────────────────────────────────────────────────────────────
    # storage: Azure Storage Account (blueprint 01-storage)
    # ─────────────────────────────────────────────────────────────────────────
    storages = optional(map(object({
      name_override               = optional(string, "")          # ASK but not Required. MAX 8 CHARACTERS. Custom storage account name; auto-generated from prefix when empty
      account_tier                = optional(string, "Standard")  # DO NOT ASK USER FOR THAT. Performance tier: Standard or Premium
      account_replication_type    = optional(string, "LRS")       # ASK but not Required. Redundancy: LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS
      account_kind                = optional(string, "StorageV2") # DO NOT ASK USER FOR THAT. Account kind: BlobStorage | BlockBlobStorage | FileStorage | Storage | StorageV2
      access_tier                 = string                        # REQUIRED. Blob access tier: Hot or Cool
      allow_public_network_access = optional(bool, true)          # DO NOT ASK USER FOR THAT. FOR NOW ONLY PUBLIC IS SUPPORTED. Set false to restrict access to private endpoints or VNet rules only
    })), null)
    
    # Azure RESOURCE CONFIGURATION
    # ─────────────────────────────────────────────────────────────────────────
    # keyvault: Azure Key Vault (blueprint 02-keyvault)
    # ─────────────────────────────────────────────────────────────────────────
    keyvaults = optional(map(object({
      name_override              = optional(string, "")   # ASK but not Required. MAX 8 CHARACTERS. Custom Key Vault name; auto-generated from prefix when empty
      soft_delete_retention_days = optional(number, 7)    # ASK but not Required. Days to retain soft-deleted secrets/keys/certs (7–90)
      purge_protection_enabled   = optional(bool, false) # ASK but not Required. Prevents permanent deletion until retention period expires
      network_acls = optional(object({  # Only ask if user wants to restrict access to Key Vault to specific IPs. If not provided, Key Vault will allow access from all networks.
        bypass                     = optional(string, "AzureServices") # ASK but not Required. Services allowed to bypass network ACLs (e.g. AzureServices)
        default_action             = optional(string, "Allow")         # ASK but not Required. Default rule when no IP/VNet rule matches: Allow or Deny
        ip_rules                   = optional(list(string), [])        # ASK but not Required. Allowed IPv4 addresses or CIDR ranges
        virtual_network_subnet_ids = optional(list(string), [])        # ASK but not Required. Allowed subnet resource IDs
      }), {})
    })), null)

    # Azure RESOURCE CONFIGURATION
    # ─────────────────────────────────────────────────────────────────────────
    # MSSQL: Azure SQL Database (blueprint 03-mssql) REQUIRES KEY VAULT ID TO STORE ADMIN CREDENTIALS
    # ─────────────────────────────────────────────────────────────────────────
    mssql_servers = optional(map(object({
      name_override                  = optional(string, "")           # Custom SQL Server name; auto-generated from prefix when empty
      database_name                  = string                         # Initial database name to create (e.g. "maindb")
      sku_name                       = string                         # Pricing tier: S0, S1, S2, S3 (Standard); P1, P2, P3 (Premium); GP_Gen5_2, GP_Gen5_4, GP_Gen5_8 (General Purpose); BC_Gen5_2, BC_Gen5_4, BC_Gen5_8 (Business Critical)
      backup_retention_days          = optional(number, 7)            # Backup retention period in days (7–35 for Basic, 7–35 for Standard, 7–35 for Premium)
    })), null)

  })
}