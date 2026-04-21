# Non-sensitive values only — sensitive values passed via GitHub Secrets → TF_VAR_* env vars in CI
location          = "eastus"
db_sku            = "B_Standard_B1ms"
vm_size           = "Standard_B2s"
app_service_sku   = "B1"
db_location       = "westus2"   # MySQL Flexible Server region (eastus/eastus2 have capacity limits on free subscriptions)
unique_suffix     = "2abc"      # Short unique suffix for globally-scoped names (Key Vault, MySQL)
enable_appservice = false        # B1 and F1 quota blocked on this subscription; frontend served via IIS on VM
