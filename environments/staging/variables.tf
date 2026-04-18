variable "location" { type = string; default = "eastus" }
variable "tenant_id" { type = string }
variable "deployer_object_id" { type = string }
variable "db_admin_password" { type = string; sensitive = true }
variable "vm_admin_password" { type = string; sensitive = true }
variable "db_sku" { type = string; default = "B_Standard_B2s" }
variable "vm_size" { type = string; default = "Standard_D2s_v3" }
variable "app_service_sku" { type = string; default = "B1" }
variable "artifact_storage_account" { type = string }
variable "artifact_storage_connection_string" { type = string; sensitive = true }
