terraform {
  backend "azurerm" {
    resource_group_name  = "rg-ecomm-shared"
    storage_account_name = "ecommtfstate4096"
    container_name       = "tfstate-shared"
    key                  = "artifacts-storage.tfstate"
  }
}
