# Init module: defines defaults (tags, prefix, location, permissions).
# No resources - variables and outputs are used by other blueprint modules.
locals {
    resource_prefix = format("%s%s","kj",var.resource_prefix)
    resource_group_name = format("%s%s", local.resource_prefix, "-demo-rg")
}


#create resource group
resource "azurerm_resource_group" "project" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}