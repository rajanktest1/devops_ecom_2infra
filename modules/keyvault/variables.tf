variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "deployer_object_id" {
  description = "Object ID of the service principal / user that runs Terraform — granted Key Vault access"
  type        = string
}

variable "db_admin_password" {
  description = "MySQL admin password to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "vm_admin_password" {
  description = "Windows VM admin password to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "suffix" {
  description = "Short unique suffix for globally-scoped Key Vault name (e.g. last 4 chars of subscription ID)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
