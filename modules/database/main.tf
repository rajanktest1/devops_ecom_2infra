locals {
  # Allow overriding MySQL region independently — eastus may lack capacity on some subscriptions
  db_location = var.db_location != null ? var.db_location : var.location
}

resource "azurerm_mysql_flexible_server" "db" {
  name                   = "mysql-${var.project}-${var.environment}-${var.suffix}"
  location               = local.db_location
  resource_group_name    = var.resource_group_name
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  sku_name               = var.sku_name
  version                = "8.0.21"

  # Public access — no VNet delegation required; allows connection from Azure-hosted resources
  # For production consider switching back to private VNet integration
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  storage {
    size_gb = 20
  }

  tags = var.tags
}

# Allow all Azure-internal traffic (0.0.0.0 is the Azure magic IP for internal services)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
  name                = "AllowAzureServices"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_flexible_database" "ecomm" {
  name                = "ecomm"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
