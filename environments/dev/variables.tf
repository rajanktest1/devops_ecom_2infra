variable "location" {
  type    = string
  default = "eastus"
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "deployer_object_id" {
  description = "Object ID of the service principal running Terraform"
  type        = string
}

variable "db_admin_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}

variable "vm_admin_password" {
  description = "Windows VM admin password (min 12 chars, complexity required)"
  type        = string
  sensitive   = true
}

variable "db_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "app_service_sku" {
  type    = string
  default = "B1"
}

variable "artifact_storage_account" {
  description = "Artifact storage account name (from shared/artifacts-storage output)"
  type        = string
}

variable "db_location" {
  description = "Override region for MySQL (null = use var.location); change if eastus has no capacity"
  type        = string
  default     = null
}

variable "unique_suffix" {
  description = "Short unique suffix for globally-scoped names such as Key Vault"
  type        = string
}
  sensitive   = true
}
