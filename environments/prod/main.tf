terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
  required_version = ">= 1.8"

  backend "azurerm" {
    resource_group_name = "rg-ecomm-shared"
    container_name      = "tfstate-prod"
    key                 = "prod.tfstate"
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

locals {
  project     = "ecomm"
  environment = "prod"
  location    = var.location
  tags = {
    project     = local.project
    environment = local.environment
    managed_by  = "terraform"
  }
  artifact_versions = jsondecode(file("${path.root}/../../versions/artifact-versions.json"))
}

resource "azurerm_resource_group" "env" {
  name     = "rg-${local.project}-${local.environment}"
  location = local.location
  tags     = local.tags
}

module "networking" {
  source              = "../../modules/networking"
  project             = local.project
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.env.name
  vnet_address_space  = "10.3.0.0/16"
  app_subnet_prefix   = "10.3.1.0/24"
  db_subnet_prefix    = "10.3.2.0/24"
  tags                = local.tags
}

module "keyvault" {
  source              = "../../modules/keyvault"
  project             = local.project
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.env.name
  tenant_id           = var.tenant_id
  deployer_object_id  = var.deployer_object_id
  db_admin_password   = var.db_admin_password
  vm_admin_password   = var.vm_admin_password
  suffix              = var.unique_suffix
  tags                = local.tags
}

module "database" {
  source              = "../../modules/database"
  project             = local.project
  environment         = local.environment
  location            = local.location
  db_location         = var.db_location
  resource_group_name = azurerm_resource_group.env.name
  db_admin_password   = var.db_admin_password
  sku_name            = var.db_sku
  tags                = local.tags
}

module "vm" {
  source                    = "../../modules/vm"
  project                   = local.project
  environment               = local.environment
  location                  = local.location
  resource_group_name       = azurerm_resource_group.env.name
  subnet_id                 = module.networking.app_subnet_id
  vm_size                   = var.vm_size
  admin_password            = var.vm_admin_password
  bootstrap_storage_account = var.artifact_storage_account
  tags                      = local.tags
}

module "appservice" {
  source              = "../../modules/appservice"
  project             = local.project
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.env.name
  sku_name            = var.app_service_sku
  tags                = local.tags
}
