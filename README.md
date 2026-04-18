# ecomm_infra — Infrastructure Repository

Terraform infrastructure and GitHub Actions CI/CD for the **ShopEmoji ecomm** application.
This is the **Infra Repo** in a split-repository architecture — it provisions and manages all Azure resources.
Application source code lives in the separate **[devops_ecom_1app](https://github.com/rajanktest1/devops_ecom_1app)** repository.

---

## Split Repository Architecture

```
ecomm/  (App Repo)                     ecomm_infra/  (This Repo)
─────────────────                       ────────────────────────────
React + Node.js source                  Terraform modules
GitHub Actions CI/CD                    GitHub Actions Terraform plan/apply
                  │                                  │
                  │  writes after every push         │  reads for audit
                  └──► versions/artifact-versions.json ◄──┘
                              (SHA + blob URLs)

Both repos deploy through Azure Blob Storage (artifact registry):
  App CI  →  uploads  backend-{sha}.zip + frontend-{sha}.zip
  App CI  →  deploys  to Azure Windows VM + App Service directly
  Infra   →  provisions  the VM, App Service, MySQL, VNet, Key Vault
```

---

## What This Repo Provisions

| Azure Resource | Module | Notes |
|---|---|---|
| Virtual Network + Subnets + NSG | `modules/networking` | App subnet + DB subnet (delegated) |
| Windows Server 2022 VM | `modules/vm` | IIS + iisnode, bootstrapped via Custom Script Extension |
| App Service (Windows) | `modules/appservice` | Hosts the React frontend via zip deploy |
| MySQL Flexible Server | `modules/database` | Private VNet endpoint only, no public access |
| Key Vault | `modules/keyvault` | Stores DB password + VM admin password |
| Blob Storage (artifacts) | `modules/artifacts-storage` | Build artifact store — separate from Terraform state |

---

## Repository Structure

```
ecomm_infra/
├── scripts/
│   ├── bootstrap-tfstate.ps1      ONE-TIME: creates Terraform state storage (Windows/PowerShell)
│   └── bootstrap-tfstate.sh       ONE-TIME: same for Linux/macOS
│
├── modules/                       Reusable Terraform modules (no state here)
│   ├── networking/                VNet, subnets, NSG
│   ├── vm/                        Windows VM + Custom Script Extension
│   │   └── bootstrap.ps1          Installs Node 20, IIS, iisnode, URL Rewrite on the VM
│   ├── appservice/                App Service Plan + Windows Web App
│   ├── database/                  MySQL Flexible Server + private DNS zone
│   ├── keyvault/                  Key Vault + secrets
│   └── artifacts-storage/         Blob Storage account module
│
├── shared/
│   └── artifacts-storage/         Artifact storage — provisioned once, shared across environments
│
├── environments/
│   ├── dev/                       Standard_B2s VM | MySQL B1ms | F1 App Service
│   ├── staging/                   Standard_D2s_v3 VM | MySQL B2s | B1 App Service
│   └── prod/                      Standard_D4s_v3 VM | MySQL D2ds GP | P1v3 App Service
│
├── versions/
│   └── artifact-versions.json     Written by App CI after every push to main (do not edit manually)
│
└── .github/
    └── workflows/
        ├── terraform-plan.yml     PR: fmt check + validate + plan for all environments
        └── terraform-apply.yml    main push: apply shared → dev → staging → prod (prod gated)
```

---

## Two Azure Storage Accounts

| | Terraform State | Build Artifacts |
|---|---|---|
| **Name** | `ecommtfstateXXXX` | `ecommartifactsXXXX` |
| **Created by** | `scripts/bootstrap-tfstate.ps1` (manual, once) | Terraform (`shared/artifacts-storage/`) |
| **Contains** | `.tfstate` per environment | `.zip` build artifacts |
| **Used by** | `backend.tf` in each environment | App CI (upload) + VM deploy script (download) |

> Terraform state is kept **outside** Terraform management intentionally — a bootstrapping requirement. If Terraform managed its own state storage, `terraform init` could never run on a fresh clone.

---

## Environment SKUs

| Resource | dev | staging | prod |
|---|---|---|---|
| VM | Standard_B2s | Standard_D2s_v3 | Standard_D4s_v3 |
| MySQL | B_Standard_B1ms | B_Standard_B2s | GP_Standard_D2ds_v4 |
| App Service | F1 (Free) | B1 | P1v3 |

---

## First-Time Setup

### Prerequisites
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in (`az login`)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.8
- Two GitHub repositories created: `ecomm` and `ecomm_infra`

---

### Step 1 — Bootstrap Terraform state storage (run once)

**Windows (PowerShell):**
```powershell
cd ecomm_infra
az login
.\scripts\bootstrap-tfstate.ps1
# Note the storage account name printed at the end
```

**Linux / macOS:**
```bash
cd ecomm_infra
az login
chmod +x scripts/bootstrap-tfstate.sh
./scripts/bootstrap-tfstate.sh
```

This creates:
- Resource group `rg-ecomm-shared`
- Storage account `ecommtfstateXXXX` (LRS, no public blob access)
- Blob containers: `tfstate-shared`, `tfstate-dev`, `tfstate-staging`, `tfstate-prod`

---

### Step 2 — Deploy shared artifact storage

```bash
cd shared/artifacts-storage
# Edit terraform.tfvars — set a unique artifact_storage_account_name

terraform init -backend-config="storage_account_name=<tfstate_account_from_step1>"
terraform apply
# Note the artifact storage account name from outputs
```

---

### Step 3 — Set GitHub Secrets & Variables

In **this repo** (ecomm_infra) → Settings → Secrets and variables → Actions:

| Type | Name | Value |
|---|---|---|
| Secret | `AZURE_CLIENT_ID` | App Registration client ID (OIDC) |
| Secret | `AZURE_TENANT_ID` | Azure AD tenant ID |
| Secret | `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| Secret | `AZURE_CLIENT_OBJECT_ID` | Service principal object ID (for Key Vault access policy) |
| Secret | `DB_ADMIN_PASSWORD` | MySQL admin password (12+ chars) |
| Secret | `VM_ADMIN_PASSWORD` | Windows VM admin password (12+ chars, complexity required) |
| Secret | `ARTIFACT_STORAGE_CONNECTION_STRING` | Connection string from artifact storage account → Access keys |
| Variable | `TFSTATE_STORAGE_ACCOUNT` | Storage account name from Step 1 |
| Variable | `ARTIFACT_STORAGE_ACCOUNT` | Storage account name from Step 2 |

---

### Step 4 — Create GitHub Environments

In this repo → Settings → Environments:

| Environment | Protection |
|---|---|
| `dev` | None (auto-deploy) |
| `staging` | None (auto-deploy after dev) |
| `prod` | Required reviewers — add yourself |

---

### Step 5 — Push to main to trigger provisioning

```bash
git push origin main
```

The `terraform-apply.yml` workflow runs: **shared → dev → staging → (approval) → prod**

After `dev` completes, copy the VM name, resource group, and App Service name from Terraform outputs and set them as GitHub Variables in the **ecomm** app repo.

---

## CI/CD Workflows

### `terraform-plan.yml` — on Pull Request

Runs for all three environments in parallel:
1. `terraform fmt -check` — formatting check
2. `terraform validate` — syntax and config validation
3. `terraform plan` — shows what will change
4. Posts plan output as a PR comment

### `terraform-apply.yml` — on push to `main`

Runs environments **sequentially** (shared → dev → staging → prod):
- `shared` and `dev`, `staging` apply automatically
- `prod` waits for a required reviewer to approve in the GitHub Actions UI

Each job runs:
```
terraform init -backend-config="storage_account_name=..."
terraform apply -auto-approve -var="..."
```

Sensitive variables (`db_admin_password`, `vm_admin_password`, etc.) are passed as `-var` flags sourced from GitHub Secrets — **never stored in `.tfvars` files**.

---

## OIDC Authentication Setup

Both this repo and `ecomm` use OIDC (no long-lived service principal secrets).

```bash
# Create App Registration for this repo
az ad app create --display-name "github-ecomm-infra"
az ad sp create --id <appId>

# Assign roles
az role assignment create --assignee <appId> --role Contributor \
    --scope /subscriptions/<subscriptionId>
az role assignment create --assignee <appId> --role "Storage Blob Data Contributor" \
    --scope /subscriptions/<subscriptionId>

# Add Federated Credential via Azure Portal:
# App Registrations → github-ecomm-infra → Certificates & secrets
# → Federated credentials → Add
# Entity: GitHub Actions — Branch
# Org/Repo: rajanktest1/devops_ecom_2infra   Branch: main
```

---

## Security Notes

- **No secrets in code.** All sensitive values flow through GitHub Secrets → `TF_VAR_*` environment variables in CI.
- **Terraform state is encrypted at rest** by Azure Storage (service-managed keys).
- **MySQL has no public endpoint** — accessible only from within the VNet via private DNS.
- **RDP (port 3389) is open** in the NSG — acceptable for this learning environment. Close it before using for anything beyond experimentation.
- **`.tfstate` files are gitignored** — they contain plaintext secrets and must never be committed.

---

## Useful Commands (local Terraform)

```bash
# Plan a specific environment
cd environments/dev
terraform init -backend-config="storage_account_name=ecommtfstateXXXX"
terraform plan \
  -var="tenant_id=..." \
  -var="deployer_object_id=..." \
  -var="db_admin_password=..." \
  -var="vm_admin_password=..." \
  -var="artifact_storage_account=..." \
  -var="artifact_storage_connection_string=..."

# Destroy a dev environment (learning cleanup)
terraform destroy -auto-approve -var="..." 
```
