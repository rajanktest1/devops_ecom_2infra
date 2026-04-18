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
    container_name      = "tfstate-staging"
    key                 = "staging.tfstate"
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

locals {
  project     = "ecomm"
  environment = "staging"
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
  vnet_address_space  = "10.2.0.0/16"
  app_subnet_prefix   = "10.2.1.0/24"
  db_subnet_prefix    = "10.2.2.0/24"
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
  tags                = local.tags
}

module "database" {
  source              = "../../modules/database"
  project             = local.project
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.env.name
  vnet_id             = module.networking.vnet_id
  db_subnet_id        = module.networking.db_subnet_id
  db_admin_password   = var.db_admin_password
  sku_name            = var.db_sku
  tags                = local.tags
}

module "vm" {
  source                              = "../../modules/vm"
  project                             = local.project
  environment                         = local.environment
  location                            = local.location
  resource_group_name                 = azurerm_resource_group.env.name
  subnet_id                           = module.networking.app_subnet_id
  vm_size                             = var.vm_size
  admin_password                      = var.vm_admin_password
  bootstrap_storage_account           = var.artifact_storage_account
  bootstrap_storage_connection_string = var.artifact_storage_connection_string
  tags                                = local.tags
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
