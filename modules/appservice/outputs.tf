output "app_service_name" {
  value = azurerm_windows_web_app.frontend.name
}

output "app_service_default_hostname" {
  value = azurerm_windows_web_app.frontend.default_hostname
}

output "app_service_id" {
  value = azurerm_windows_web_app.frontend.id
}
