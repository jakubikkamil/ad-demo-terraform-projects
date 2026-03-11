#create backend storage config
terraform {
  backend "azurerm" {
    resource_group_name   = "kj-storage-public-rg"
    storage_account_name  = "kjpublictfstate001"
    container_name        = "tfstate"
    key                   = "falcon3.terraform.tfstate"
  }
}