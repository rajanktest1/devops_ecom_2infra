variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }

variable "sku_name" {
  description = "App Service Plan SKU (F1 = free, B1, P1v3 etc.)"
  type        = string
  default     = "F1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
