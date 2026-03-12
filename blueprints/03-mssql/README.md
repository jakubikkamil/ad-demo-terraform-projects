# MSSQL Server and Database Blueprint

This blueprint creates an Azure SQL Server and Database with enterprise-grade security, backup, and compliance features.

## Overview

The MSSQL blueprint (`03-mssql`) provides:

- **SQL Server**: Fully managed relational database server
- **SQL Database**: Single database with configurable SKU and performance
- **Security**: TLS enforcement, firewall rules, Azure AD integration
- **High Availability**: Zone redundancy, geo-replication, backups
- **Compliance**: Auditing, Transparent Data Encryption (TDE), Vulnerability Assessment
- **Management**: Automated backups, long-term retention, monitoring

## Features

### SQL Server
- Configurable version (v11 or v12)
- Azure AD administrator support
- Managed identity for server features
- TLS enforcement (configurable minimum version)
- Public/private network access control

### SQL Database
- Flexible SKU options (Standard, Premium, General Purpose, Business Critical)
- Automatic backups (7-35 days configurable)
- Geo-backup to paired region
- Long-term retention (optional)
- Zone redundancy for high availability
- Point-in-time restore

### Security
- Firewall rules (IP-based access control)
- Azure Services access (always allowed)
- Custom IP ranges support
- TDE with Key Vault support
- Auditing and logging
- Vulnerability assessment

### Networking
- Public or private database access
- Firewall rules for specific IP ranges
- Azure Services bypass
- Encryption in transit

## File Structure

```
03-mssql/
├── main.tf              # SQL Server, Database, Firewall, Security policies
├── variables.tf         # All configurable parameters with validation
├── outputs.tf           # Connection strings, ids, configuration details
├── versions.tf          # Provider requirements
└── mssql_plan.tftest.hcl # Automated tests
```

## Usage

### Basic Example

```hcl
module "mssql" {
  source = "./blueprints/03-mssql"

  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  resource_prefix               = "myapp"
  administrator_login           = "sqladmin"
  administrator_login_password  = var.sql_password  # Use from Key Vault
  database_name                 = "appdb"
  tags                          = local.tags
}
```

### Production Example (with security)

```hcl
module "mssql" {
  source = "./blueprints/03-mssql"

  resource_group_name           = azurerm_resource_group.prod.name
  location                      = "westeurope"
  resource_prefix               = "prodapp"
  
  # Authentication
  administrator_login           = "dba"
  administrator_login_password  = data.azurerm_key_vault_secret.sql_password.value
  
  # Azure AD Integration
  enable_azure_ad_admin         = true
  azure_ad_admin_login          = "dba-group@mycompany.com"
  azure_ad_admin_object_id      = data.azuread_group.dba.object_id
  azure_ad_only_authentication  = false  # Allow both AD and SQL auth
  
  # Database Configuration
  database_name                 = "productiondb"
  sku_name                      = "GP_Gen5_4"  # General Purpose, Gen5, 4 cores
  max_size_gb                   = 500
  zone_redundant                = true
  
  # Backups & Recovery
  backup_retention_days         = 30
  enable_geo_backup             = true
  enable_long_term_retention    = true
  long_term_retention_weekly    = "W12"
  long_term_retention_monthly   = "M3"
  long_term_retention_yearly    = "Y5"
  
  # Security
  minimum_tls_version           = "1.2"
  allow_public_network_access   = false
  enable_managed_identity       = true
  
  # Firewall
  allowed_ip_ranges = {
    "office_network" = {
      start_ip = "203.0.113.0"
      end_ip   = "203.0.113.255"
    }
    "vpn_gateway" = {
      start_ip = "198.51.100.0"
      end_ip   = "198.51.100.255"
    }
  }
  
  # Auditing
  enable_auditing             = true
  audit_retention_days        = 180
  audit_storage_endpoint      = "https://mysa.blob.core.windows.net"
  audit_storage_account_key   = data.azurerm_key_vault_secret.storage_key.value
  
  # Encryption
  tde_key_vault_key_id        = azurerm_key_vault_key.mssql.id
  
  tags = local.tags
}
```

## Configuration Parameters

### Required
- `resource_group_name`: Azure resource group name
- `location`: Azure region
- `administrator_login`: SQL admin username
- `administrator_login_password`: SQL admin password (8+ chars, uppercase, lowercase, numeric, special)
- `database_name`: Database name

### Database SKU Options

**Standard Tier (S0-S12)**
- `S0`: 10 DTU, 250 GB
- `S1`: 20 DTU, 250 GB
- `S2`: 50 DTU, 250 GB
- `S3`: 100 DTU, 250 GB

**Premium Tier (P1-P15)**
- `P1`: 125 DTU, 500 GB
- `P2`: 250 DTU, 500 GB
- `P4`: 500 DTU, 500 GB
- `P6`: 1000 DTU, 500 GB

**vCore Models (Gen5)**
- `GP_Gen5_2`: General Purpose, 2 cores, 32 GB RAM
- `GP_Gen5_4`: General Purpose, 4 cores, 64 GB RAM
- `BC_Gen5_2`: Business Critical, 2 cores, 32 GB RAM
- `BC_Gen5_4`: Business Critical, 4 cores, 64 GB RAM

## Outputs

```hcl
# Connection Details
output "sql_server_fqdn"        # e.g., myserver.database.windows.net
output "sql_database_name"      # Database name
output "connection_details"     # Full connection info object

# Security & Access
output "sql_server_id"          # Azure resource ID
output "firewall_rules"         # Created firewall rules

# Configuration
output "database_configuration" # SKU, size, redundancy settings
output "backup_configuration"   # Retention and recovery settings
output "encryption_status"      # TDE status and key info

# Recovery
output "connection_string_sqlauth"  # Conn string with SQL auth (sensitive)
```

## Common Use Cases

### Development Database
```json
{
  "sku_name": "S0",
  "max_size_gb": 20,
  "backup_retention_days": 7,
  "enable_auditing": false,
  "allow_public_network_access": true
}
```

### Production Database (Highly Available)
```json
{
  "sku_name": "GP_Gen5_4",
  "max_size_gb": 500,
  "zone_redundant": true,
  "backup_retention_days": 30,
  "enable_long_term_retention": true,
  "enable_auditing": true,
  "allow_public_network_access": false,
  "enable_azure_ad_admin": true
}
```

### Business Critical (Maximum Protection)
```json
{
  "sku_name": "BC_Gen5_4",
  "zone_redundant": true,
  "backup_retention_days": 35,
  "enable_long_term_retention": true,
  "long_term_retention_weekly": "W52",
  "long_term_retention_monthly": "M60",
  "long_term_retention_yearly": "Y10",
  "enable_auditing": true,
  "enable_vulnerability_assessment": true,
  "tde_key_vault_key_id": "key_vault_key_id"
}
```

## Integration with Other Blueprints

The MSSQL blueprint can be integrated with:

- **00-init**: Uses resource group and tags from init
- **02-keyvault**: Store admin password and audit logs key
- **Application modules**: Reference outputs for connection strings

### Example: Project Integration

```hcl
module "init" {
  source = "../blueprints/00-init"
  # ...
}

module "keyvault" {
  for_each = var.config.keyvaults
  source   = "../blueprints/02-keyvault"
  
  resource_group_name = module.init.resource_group_name
  # ...
}

module "mssql" {
  source = "../blueprints/03-mssql"
  
  resource_group_name           = module.init.resource_group_name
  location                      = module.init.location
  resource_prefix               = module.init.resource_prefix
  tags                          = module.init.tags
  
  # Get password from Key Vault
  administrator_login_password  = data.azurerm_key_vault_secret.sql_password.value
  
  depends_on = [module.keyvault]
}
```

## Security Best Practices

1. **Password Management**
   - Store in Azure Key Vault
   - Use strong, complex passwords (8+ chars, mixed case, numbers, symbols)
   - Rotate regularly

2. **Network Security**
   - Disable public access when possible (`allow_public_network_access = false`)
   - Use firewall rules to restrict to specific IPs
   - Use Private Endpoints for connection from VNets

3. **Authentication**
   - Enable Azure AD authentication
   - Use managed identities for application connections
   - Disable SQL-only authentication when possible

4. **Encryption**
   - Use customer-managed keys in Key Vault for TDE
   - Enable encryption in transit (TLS 1.2+)
   - Enable auditing and vulnerability assessment

5. **Backups**
   - Retain backups for at least 30 days in production
   - Enable long-term retention for compliance
   - Test restore procedures regularly

## Troubleshooting

### Password Validation Error
**Error**: "Password must be 8-128 characters with uppercase, lowercase, numeric, and special characters"

**Fix**: Ensure password meets requirements:
```
✓ At least 8 characters
✓ Contains uppercase letters (A-Z)
✓ Contains lowercase letters (a-z)
✓ Contains numbers (0-9)
✓ Contains special characters (!@#$%^&*...)
```

### Database Name Validation Error
**Error**: "Database name must be 1-128 characters..."

**Fix**: Database names must:
- Start with letter, #, or _
- Be 1-128 characters long
- Contain only alphanumeric/@/$/#/_

### Firewall Rule Conflicts
**Error**: "Rule with name already exists"

**Fix**: Use unique names for firewall rules or update existing ones

### Connection String Issues
**Error**: "Cannot open server 'xxx' requested by login"

**Fix**: Verify:
- Server name/FQDN is correct
- Database name is correct
- Login and password are correct
- Firewall rule allows your IP

## Testing

Run automated tests:

```bash
cd blueprints/03-mssql
terraform test

# Or test specific configuration
terraform test -var-file=../ENVVARS/03-mssql.json
```

## Related Resources

- [Azure SQL Database Pricing](https://azure.microsoft.com/pricing/details/sql-database/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [Terraform Azure SQL Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database)
- [Connection String Reference](https://www.connectionstrings.com/sql-server/)

## Support

For issues or questions:
1. Check test files for example configurations
2. Review deployment logs for error details
3. Consult Azure SQL documentation
4. Check firewall and network settings
