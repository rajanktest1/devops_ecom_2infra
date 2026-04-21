output "vm_public_ip" {
  description = "Public IP of the backend Windows VM — use this for RDP"
  value       = module.vm.public_ip_address
}

output "vm_name" {
  value = module.vm.vm_name
}

output "frontend_url" {
  value = length(module.appservice) > 0 ? "https://${module.appservice[0].app_service_default_hostname}" : "http://${module.vm.public_ip_address}"
}

output "mysql_fqdn" {
  value = module.database.mysql_fqdn
}

output "resource_group" {
  value = azurerm_resource_group.env.name
}
