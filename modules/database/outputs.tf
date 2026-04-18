output "mysql_server_name" {
  value = azurerm_mysql_flexible_server.db.name
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.db.fqdn
}

output "mysql_database_name" {
  value = azurerm_mysql_flexible_database.ecomm.name
}
