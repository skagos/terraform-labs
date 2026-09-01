# Floci-AZ Terraform Lab 02

Lab 02 builds a small two-tier environment in a new resource group. It extends Lab 01 with reusable values, `for_each`, subnet isolation, a network security rule, and private blob storage.

## Resources

| Resource | Name | Purpose |
|---|---|---|
| Resource group | `rg-lab02` | Isolates Lab 02 |
| Virtual network | `vnet-lab02` | Provides `10.20.0.0/16` |
| Web subnet | `snet-web` | Uses `10.20.1.0/24` |
| Data subnet | `snet-data` | Uses `10.20.2.0/24` |
| Network security group | `nsg-lab02-web` | Allows inbound HTTPS on port 443 |
| Storage account | `lab02storage001` | Provides local Azure-style storage |
| Blob container | `documents` | Private application content |

## Dependency flow

```text
rg-lab02
|-- vnet-lab02
|   |-- snet-web ---- nsg-lab02-web
|   `-- snet-data
`-- lab02storage001
    `-- documents
```

Complete the shared setup and certificate steps in [`../README.md`](../README.md) first.

## Run the lab

Start Floci-AZ from `floci-ui`:

```powershell
cd ..\floci-ui
docker compose --profile multicloud up -d floci-az floci-api floci-ui
```

Initialize and validate Lab 02:

```powershell
cd ..\lab02
terraform init
terraform fmt -check
terraform validate
```

Review and deploy:

```powershell
terraform plan
terraform apply
```

Confirm with `yes`. Then inspect Terraform's view of the environment:

```powershell
terraform output
terraform state list
```

## Expected state

```text
azurerm_network_security_group.web
azurerm_resource_group.lab02
azurerm_storage_account.lab02
azurerm_subnet.lab02["data"]
azurerm_subnet.lab02["web"]
azurerm_subnet_network_security_group_association.web
azurerm_virtual_network.lab02
```

## Verify in Floci-AZ

```powershell
$subscriptionId = "00000000-0000-0000-0000-000000000001"
$baseUri = "http://localhost:4577/subscriptions/$subscriptionId/resourceGroups/rg-lab02/providers"

Invoke-RestMethod `
  "$baseUri/Microsoft.Network/virtualNetworks/vnet-lab02?api-version=2024-05-01" |
Select-Object name, location, id

Invoke-RestMethod `
  "$baseUri/Microsoft.Network/networkSecurityGroups/nsg-lab02-web?api-version=2024-05-01" |
Select-Object name, location, id

Invoke-RestMethod `
  "$baseUri/Microsoft.Storage/storageAccounts/lab02storage001?api-version=2023-01-01" |
Select-Object name, location, id
```

## Clean up

```powershell
terraform destroy
```

Confirm with `yes`. `terraform state list` should then be empty.

## What this lab demonstrates

- Isolating infrastructure in a dedicated resource group
- Using locals and a variable to avoid repeated values
- Creating multiple resources with `for_each`
- Connecting subnets, security controls, and storage through dependencies
- Comparing Terraform state with direct ARM API responses
