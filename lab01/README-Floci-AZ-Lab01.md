# Floci-AZ Terraform Lab 01

This lab uses Terraform and the AzureRM provider to create Azure-style resources locally in Floci-AZ. It does not require an Azure subscription and does not create resources in Azure.

The configuration creates:

- one resource group: `rg-lab01`
- one storage account: `lab01storage001`
- one virtual network: `vnet-lab01` with address space `10.10.0.0/16`

## How the lab fits together

```text
Labs/
|-- README.md                 Shared setup and requirements
|-- .gitignore               Excludes the cloned floci-ui repository
|-- floci-ui/                Local emulator and UI (external dependency)
|   |-- docker-compose.yml
|   `-- docker-compose.override.yml
`-- lab01/                   This Terraform lab
    |-- providers.tf
    `-- main.tf
```

```text
Terraform + AzureRM
        |
        | HTTPS metadata discovery and ARM requests
        v
Floci-AZ at localhost:4577
        |
        +-- Resource Group
        +-- Storage Account
        `-- Virtual Network

Floci UI at localhost:4500
        |
        v
Floci API at localhost:4501
```

Read the shared [`../README.md`](../README.md) first. It explains the required tools, how to clone `floci-ui`, the Compose override, and why the local TLS certificate must be trusted.

## 1. Start the local Floci stack

From the `floci-ui` sibling directory:

```powershell
cd ..\floci-ui
docker compose --profile multicloud up -d --build floci-az floci-api floci-ui
docker compose ps
```

Verify Floci-AZ and the UI's Azure connection:

```powershell
Invoke-RestMethod http://localhost:4577/_floci/health
Invoke-RestMethod http://localhost:4501/api/clouds/azure/status
```

Open the UI at <http://localhost:4500>.

> The Floci UI is not a complete replacement for the Azure Portal. Supported resources may be visible there, but ARM resources such as resource groups and virtual networks may need to be verified through the API commands below.

## 2. Initialize and validate Terraform

Return to this lab directory:

```powershell
cd ..\lab01
terraform init
terraform fmt -check
terraform validate
```

The provider configuration in `providers.tf` deliberately uses placeholder credentials. `environment = "stack"` and `metadata_host = "localhost:4577"` redirect AzureRM to the local Floci-AZ endpoint, while `resource_provider_registrations = "none"` prevents automatic Azure resource-provider registration.

## 3. Preview and apply

```powershell
terraform plan
terraform apply
```

Confirm the apply by typing `yes`. On a clean lab, the plan should report:

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

## 4. Verify Terraform state

```powershell
terraform output
terraform state list
```

Expected state entries:

```text
azurerm_resource_group.lab01
azurerm_storage_account.lab01
azurerm_virtual_network.lab01
```

Expected outputs:

```text
resource_group  = "rg-lab01"
storage_account = "lab01storage001"
virtual_network = "vnet-lab01"
```

## 5. Verify the resources directly in Floci-AZ

These checks query the emulator rather than Terraform state, proving that the resources exist in Floci-AZ.

```powershell
$subscriptionId = "00000000-0000-0000-0000-000000000001"
```

### Resource group

```powershell
(Invoke-RestMethod `
  "http://localhost:4577/subscriptions/$subscriptionId/resourceGroups?api-version=2021-04-01").value |
Select-Object name, location, id |
Format-Table -AutoSize
```

### Storage account

```powershell
Invoke-RestMethod `
  "http://localhost:4577/subscriptions/$subscriptionId/resourceGroups/rg-lab01/providers/Microsoft.Storage/storageAccounts/lab01storage001?api-version=2023-01-01" |
Select-Object name, location, id |
Format-List
```

### Virtual network

```powershell
Invoke-RestMethod `
  "http://localhost:4577/subscriptions/$subscriptionId/resourceGroups/rg-lab01/providers/Microsoft.Network/virtualNetworks/vnet-lab01?api-version=2024-05-01" |
Select-Object name, location, id |
Format-List
```

## 6. Clean up

Destroy the emulated infrastructure:

```powershell
terraform destroy
```

After confirming with `yes`, `terraform state list` should return no resources.

Stop the local services from the Floci UI directory:

```powershell
cd ..\floci-ui
docker compose --profile multicloud down
```

To start the services again later:

```powershell
docker compose --profile multicloud up -d floci-az floci-api floci-ui
```

## Troubleshooting

### Certificate verification fails

If `terraform init`, `plan`, or `apply` reports an `x509`, unknown authority, or certificate trust error, repeat the certificate installation from the shared README. Download a fresh certificate after recreating the Floci-AZ data or TLS files.

### Port already in use

Check whether another process or container is using ports `4500`, `4501`, or `4577`:

```powershell
docker compose ps
Get-NetTCPConnection -LocalPort 4500,4501,4577 -ErrorAction SilentlyContinue
```

### UI does not show a Terraform resource

Use `terraform state list` and the direct Floci-AZ REST checks above. UI visibility and resource existence are separate concerns.

## What this lab demonstrates

- Redirecting the AzureRM provider to a local Azure-compatible endpoint
- Creating related resources through Terraform dependencies
- Comparing desired configuration, Terraform state, and emulator state
- Using a trusted local TLS certificate for provider metadata discovery
