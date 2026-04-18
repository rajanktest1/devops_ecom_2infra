output "storage_account_name" {
  value = azurerm_storage_account.artifacts.name
}

output "storage_account_id" {
  value = azurerm_storage_account.artifacts.id
}

output "primary_connection_string" {
  value     = azurerm_storage_account.artifacts.primary_connection_string
  sensitive = true
}
