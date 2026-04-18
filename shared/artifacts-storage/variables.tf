variable "location" {
  description = "Azure region for shared resources"
  type        = string
  default     = "eastus"
}

variable "artifact_storage_account_name" {
  description = "Globally unique name for the artifact storage account (e.g. ecommartifacts1234)"
  type        = string
}
