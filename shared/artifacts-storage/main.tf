terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
  required_version = ">= 1.8"
}

provider "azurerm" {
  features {}
  # use_oidc = true   # enabled in CI via GitHub Actions; local runs use az login
}

resource "azurerm_resource_group" "shared" {
  name     = "rg-ecomm-shared"
  location = var.location
  tags     = local.tags
}

module "artifacts_storage" {
  source               = "../../modules/artifacts-storage"
  storage_account_name = var.artifact_storage_account_name
  resource_group_name  = azurerm_resource_group.shared.name
  location             = azurerm_resource_group.shared.location
  tags                 = local.tags
}

locals {
  tags = {
    project     = "ecomm"
    environment = "shared"
    managed_by  = "terraform"
  }
}
