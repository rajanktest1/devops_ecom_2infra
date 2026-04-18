variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 lowercase alphanumeric chars)"
  type        = string
}

variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}
