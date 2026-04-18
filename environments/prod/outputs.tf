output "vm_public_ip" { value = module.vm.public_ip_address }
output "vm_name" { value = module.vm.vm_name }
output "frontend_url" { value = "https://${module.appservice.app_service_default_hostname}" }
output "mysql_fqdn" { value = module.database.mysql_fqdn }
output "resource_group" { value = azurerm_resource_group.env.name }
