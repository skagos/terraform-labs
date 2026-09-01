resource "azurerm_resource_group" "lab01" {
  name     = "rg-lab01"
  location = "eastus"
}

resource "azurerm_storage_account" "lab01" {
  name                     = "lab01storage001"
  resource_group_name      = azurerm_resource_group.lab01.name
  location                 = azurerm_resource_group.lab01.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_network" "lab01" {
  name                = "vnet-lab01"
  location            = azurerm_resource_group.lab01.location
  resource_group_name = azurerm_resource_group.lab01.name

  address_space = [
    "10.10.0.0/16"
  ]
}
output "resource_group" {
  value = azurerm_resource_group.lab01.name
}

output "storage_account" {
  value = azurerm_storage_account.lab01.name
}

output "virtual_network" {
  value = azurerm_virtual_network.lab01.name
}