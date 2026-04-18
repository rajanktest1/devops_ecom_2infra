# bootstrap-tfstate.ps1
# Run ONCE locally before any Terraform commands.
# Creates the Azure Storage Account used to store Terraform remote state.
# Prerequisites: az login (or az login --use-device-code), Azure CLI installed.

[CmdletBinding()]
param(
    [string]$Location        = 'eastus',
    [string]$ResourceGroup   = 'rg-ecomm-shared',
    [string]$StorageAccount  = "ecommtfstate$(Get-Random -Minimum 1000 -Maximum 9999)",
    [string]$SubscriptionId  = ''   # leave blank to use current az context
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "============================================================"
Write-Host "  ecomm — Terraform State Bootstrap"
Write-Host "============================================================"
Write-Host ""

# Optionally set subscription
if ($SubscriptionId) {
    Write-Host "==> Setting subscription: $SubscriptionId"
    az account set --subscription $SubscriptionId
}

$currentSub = az account show --query id -o tsv
Write-Host "==> Using subscription: $currentSub"

# Create resource group
Write-Host "==> Creating resource group: $ResourceGroup in $Location..."
az group create `
    --name $ResourceGroup `
    --location $Location `
    --output none

# Create storage account (LRS, no public blob access)
Write-Host "==> Creating storage account: $StorageAccount..."
az storage account create `
    --name $StorageAccount `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --allow-blob-public-access false `
    --min-tls-version TLS1_2 `
    --output none

# Create containers (one per environment + one for shared)
$containers = @('tfstate-shared', 'tfstate-dev', 'tfstate-staging', 'tfstate-prod')
foreach ($container in $containers) {
    Write-Host "==> Creating container: $container..."
    az storage container create `
        --name $container `
        --account-name $StorageAccount `
        --auth-mode login `
        --output none
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Bootstrap complete!"
Write-Host "============================================================"
Write-Host ""
Write-Host "  Storage account name : $StorageAccount"
Write-Host "  Resource group       : $ResourceGroup"
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Copy the storage account name above."
Write-Host "  2. In both GitHub repos, set the following GitHub Variable:"
Write-Host "       TFSTATE_STORAGE_ACCOUNT = $StorageAccount"
Write-Host "  3. Update environments/*/backend.tf with:"
Write-Host "       storage_account_name = `"$StorageAccount`""
Write-Host "  4. Run: cd shared/artifacts-storage && terraform init && terraform apply"
Write-Host "  5. Push your infra repo — Terraform Apply workflow will provision everything."
Write-Host ""
