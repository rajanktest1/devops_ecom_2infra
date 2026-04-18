#!/usr/bin/env bash
# bootstrap-tfstate.sh
# Run ONCE locally before any Terraform commands.
# Creates the Azure Storage Account used to store Terraform remote state.
# Prerequisites: az login, Azure CLI installed.

set -euo pipefail

LOCATION="${LOCATION:-eastus}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ecomm-shared}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-ecommtfstate$RANDOM}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"

echo ""
echo "============================================================"
echo "  ecomm — Terraform State Bootstrap"
echo "============================================================"
echo ""

if [ -n "$SUBSCRIPTION_ID" ]; then
    echo "==> Setting subscription: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
fi

CURRENT_SUB=$(az account show --query id -o tsv)
echo "==> Using subscription: $CURRENT_SUB"

echo "==> Creating resource group: $RESOURCE_GROUP in $LOCATION..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo "==> Creating storage account: $STORAGE_ACCOUNT..."
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --allow-blob-public-access false \
    --min-tls-version TLS1_2 \
    --output none

for CONTAINER in tfstate-shared tfstate-dev tfstate-staging tfstate-prod; do
    echo "==> Creating container: $CONTAINER..."
    az storage container create \
        --name "$CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --output none
done

echo ""
echo "============================================================"
echo "  Bootstrap complete!"
echo "============================================================"
echo ""
echo "  Storage account name : $STORAGE_ACCOUNT"
echo "  Resource group       : $RESOURCE_GROUP"
echo ""
echo "  Next steps:"
echo "  1. Copy the storage account name above."
echo "  2. In both GitHub repos, set the following GitHub Variable:"
echo "       TFSTATE_STORAGE_ACCOUNT = $STORAGE_ACCOUNT"
echo "  3. Update environments/*/backend.tf with:"
echo "       storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  4. Run: cd shared/artifacts-storage && terraform init && terraform apply"
echo "  5. Push your infra repo — Terraform Apply workflow provisions everything."
echo ""
