# ═══════════════════════════════════════════════════════════════════════════
# Variables for MSSQL Server and Database Blueprint
# ═══════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────
# Required Variables (from parent module)
# ─────────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the SQL server."
}

variable "location" {
  type        = string
  description = "Azure region for the SQL server and database."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for resource names (from init module)."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

# ─────────────────────────────────────────────────────────────────────────
# SQL Server Configuration
# ─────────────────────────────────────────────────────────────────────────

variable "name_override" {
  type        = string
  description = "Optional override for SQL server name. If empty, name is derived from prefix."
  default     = ""
}

variable "server_version" {
  type        = string
  description = "The version for the new server. Valid values are 2.0 (for v11.0 server) and 12.0 (for v12.0 server)."
  default     = "12.0"

  validation {
    condition     = contains(["2.0", "12.0"], var.server_version)
    error_message = "Server version must be 2.0 or 12.0."
  }
}

variable "administrator_login" {
  type        = string
  description = "The administrator login name for the new server."
  sensitive   = false

  validation {
    condition     = can(regex("^[a-zA-Z_][a-zA-Z0-9_]{0,127}$", var.administrator_login))
    error_message = "Administrator login must start with letter or underscore and contain only alphanumeric characters and underscores."
  }
}

variable "administrator_login_password" {
  type        = string
  description = "The password associated with the administrator_login user. Must be between 8 and 128 characters, contain uppercase, lowercase, numeric, and special characters."
  sensitive   = true

  validation {
    condition = length(var.administrator_login_password) >= 8 && (
      can(regex("[A-Z]", var.administrator_login_password)) &&
      can(regex("[a-z]", var.administrator_login_password)) &&
      can(regex("[0-9]", var.administrator_login_password)) &&
      can(regex("[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,./<>?]", var.administrator_login_password))
    )
    error_message = "Password must be 8-128 characters with uppercase, lowercase, numeric, and special characters."
  }
}

variable "minimum_tls_version" {
  type        = string
  description = "The Minimum TLS Version for all SQL Database and SQL Data Warehouse databases."
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be 1.0, 1.1, or 1.2."
  }
}

variable "allow_public_network_access" {
  type        = bool
  description = "Whether public network access is enabled for this server."
  default     = true
}

variable "enable_managed_identity" {
  type        = bool
  description = "Enable system assigned managed identity for the server."
  default     = false
}

# ─────────────────────────────────────────────────────────────────────────
# Azure AD Integration
# ─────────────────────────────────────────────────────────────────────────

variable "enable_azure_ad_admin" {
  type        = bool
  description = "Enable Azure AD administrator for the SQL server."
  default     = false
}

variable "azure_ad_admin_login" {
  type        = string
  description = "The login name of the Azure AD administrator."
  default     = ""
}

variable "azure_ad_admin_object_id" {
  type        = string
  description = "The object ID of the Azure AD administrator user, group, or service principal."
  default     = ""
}

variable "azure_ad_only_authentication" {
  type        = bool
  description = "Enable Azure AD only authentication (disables SQL authentication)."
  default     = false
}

# ─────────────────────────────────────────────────────────────────────────
# Firewall Rules
# ─────────────────────────────────────────────────────────────────────────

variable "allowed_ip_ranges" {
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  description = "Map of firewall rule names to IP address ranges. Use CIDR notation like '192.168.0.0' to '192.168.0.255'."
  default     = {}

  # Example:
  # {
  #   "office_network" = { start_ip = "203.0.113.0", end_ip = "203.0.113.255" }
  #   "vpn_network"    = { start_ip = "198.51.100.0", end_ip = "198.51.100.255" }
  # }
}

# ─────────────────────────────────────────────────────────────────────────
# SQL Database Configuration
# ─────────────────────────────────────────────────────────────────────────

variable "database_name" {
  type        = string
  description = "The name of the MSSQL Database."

  validation {
    condition     = can(regex("^[a-zA-Z#_][a-zA-Z0-9@$#_]{0,127}$", var.database_name))
    error_message = "Database name must be 1-128 characters, start with letter/# /_,  and contain only alphanumeric/@/#/$/_."
  }
}

variable "database_collation" {
  type        = string
  description = "Specifies the collation for the database."
  default     = "SQL_Latin1_General_CP1_CI_AS"

  # Common collations:
  # SQL_Latin1_General_CP1_CI_AS - Case-insensitive, accent-sensitive (default)
  # Latin1_General_CI_AS - SQL Server compatible
  # SQL_Latin1_General_CP1_CS_AS - Case-sensitive, accent-sensitive
}

variable "sku_name" {
  type        = string
  description = "Specifies the name of the sku used by the database. For example, GP_S_Gen5_2, HS_Gen4_1, DW1000c, ElasticPool."
  default     = "S0"

  # Common SKUs:
  # S0, S1, S2, S3, S4, S6, S7, S9, S12 (Standard)
  # P1, P2, P4, P6, P11, P15 (Premium)
  # GP_Gen5_2 (General Purpose)
  # BC_Gen5_2 (Business Critical)
}

variable "max_size_gb" {
  type        = number
  description = "The max size of the database in gigabytes."
  default     = 20

  validation {
    condition     = var.max_size_gb > 0 && var.max_size_gb <= 1048576
    error_message = "Max size must be between 1 and 1048576 GB."
  }
}

variable "zone_redundant" {
  type        = bool
  description = "Whether this database is zone redundant."
  default     = false
}

# ─────────────────────────────────────────────────────────────────────────
# Backup & Retention Policies
# ─────────────────────────────────────────────────────────────────────────

variable "backup_retention_days" {
  type        = number
  description = "Point-in-time restore retention in days (1-35 for Basic/Standard, 1-35 for Premium)."
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "enable_geo_backup" {
  type        = bool
  description = "Enable geo-backup (automatic backup to paired region)."
  default     = true
}

variable "enable_long_term_retention" {
  type        = bool
  description = "Enable long-term retention backups."
  default     = false
}

variable "long_term_retention_weekly" {
  type        = string
  description = "Long-term retention weekly backup retention (W3, W4, ... W52, or OFF)."
  default     = "OFF"
}

variable "long_term_retention_monthly" {
  type        = string
  description = "Long-term retention monthly backup retention (M3, M6, M9, M12, ... M36, or OFF)."
  default     = "OFF"
}

variable "long_term_retention_yearly" {
  type        = string
  description = "Long-term retention yearly backup retention (Y1, Y2, ... Y5, or OFF)."
  default     = "OFF"
}

variable "long_term_retention_week_of_year" {
  type        = number
  description = "Long-term retention week of year (1-52)."
  default     = 1

  validation {
    condition     = var.long_term_retention_week_of_year >= 1 && var.long_term_retention_week_of_year <= 52
    error_message = "Week of year must be between 1 and 52."
  }
}

# ─────────────────────────────────────────────────────────────────────────
# Auditing & Security
# ─────────────────────────────────────────────────────────────────────────

variable "enable_auditing" {
  type        = bool
  description = "Enable database auditing."
  default     = false
}

variable "audit_retention_days" {
  type        = number
  description = "Number of days to keep audit logs."
  default     = 90

  validation {
    condition     = var.audit_retention_days >= 0 && var.audit_retention_days <= 2147483647
    error_message = "Audit retention must be between 0 and 2147483647 days."
  }
}

variable "audit_storage_endpoint" {
  type        = string
  description = "The storage account endpoint for audit logs (blob storage)."
  default     = ""
}

variable "audit_storage_account_key" {
  type        = string
  description = "The storage account key for audit logs."
  sensitive   = true
  default     = ""
}

variable "audit_actions_and_groups" {
  type        = list(string)
  description = "List of audit actions and groups to track."
  default = [
    "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP",
    "FAILED_DATABASE_AUTHENTICATION_GROUP",
    "BATCH_COMPLETED_GROUP"
  ]
}

variable "enable_vulnerability_assessment" {
  type        = bool
  description = "Enable vulnerability assessment for the database."
  default     = false
}

# ─────────────────────────────────────────────────────────────────────────
# Encryption
# ─────────────────────────────────────────────────────────────────────────

variable "tde_key_vault_key_id" {
  type        = string
  description = "The URL of the Key Vault key to use for Transparent Data Encryption. Leave empty to use Microsoft-managed key."
  default     = ""
}
