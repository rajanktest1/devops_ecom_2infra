variable "location" { type = string; default = "eastus" }
variable "tenant_id" { type = string }
variable "deployer_object_id" { type = string }
variable "db_admin_password" { type = string; sensitive = true }
variable "vm_admin_password" { type = string; sensitive = true }
variable "db_sku" { type = string; default = "GP_Standard_D2ds_v4" }
variable "vm_size" { type = string; default = "Standard_D4s_v3" }
variable "app_service_sku" { type = string; default = "P1v3" }
variable "enable_appservice" { type = bool; default = true }
variable "artifact_storage_account" { type = string }
variable "db_location" { type = string; default = null }
variable "unique_suffix" { type = string }
