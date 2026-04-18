variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "ID of the subnet to place the VM NIC into"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size (e.g. Standard_B2s, Standard_D2s_v3)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Local administrator username for the Windows VM"
  type        = string
  default     = "ecommadmin"
}

variable "admin_password" {
  description = "Local administrator password — sourced from Key Vault output"
  type        = string
  sensitive   = true
}

variable "bootstrap_storage_account" {
  description = "Storage account name where bootstrap.ps1 is uploaded"
  type        = string
}

variable "bootstrap_storage_container" {
  description = "Container in the bootstrap storage account"
  type        = string
  default     = "artifacts"
}

variable "bootstrap_storage_connection_string" {
  description = "Connection string for SAS token generation for bootstrap blob"
  type        = string
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
