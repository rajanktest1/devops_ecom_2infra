output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "db_password_secret_id" {
  value = azurerm_key_vault_secret.db_password.id
}

output "vm_password_secret_id" {
  value = azurerm_key_vault_secret.vm_admin_password.id
}
