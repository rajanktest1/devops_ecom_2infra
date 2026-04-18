resource "azurerm_storage_account" "artifacts" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # No public blob access — CI uses az identity, VM uses SAS tokens
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.artifacts.name
  container_access_type = "private"
}
