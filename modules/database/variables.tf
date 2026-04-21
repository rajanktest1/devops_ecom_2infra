variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }

variable "db_location" {
  description = "Override region for MySQL Flexible Server (null = use var.location)"
  type        = string
  default     = null
}

variable "resource_group_name" { type = string }

variable "db_admin_username" {
  description = "MySQL administrator username"
  type        = string
  default     = "ecommdbadmin"
}

variable "db_admin_password" {
  description = "MySQL administrator password — sourced from Key Vault"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "MySQL Flexible Server SKU (e.g. B_Standard_B1ms, GP_Standard_D2ds_v4)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "tags" {
  type    = map(string)
  default = {}
}
