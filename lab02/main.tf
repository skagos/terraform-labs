locals {
  resource_group_name  = "rg-lab02"
  virtual_network_name = "vnet-lab02"
  storage_account_name = "lab02storage001"

  subnets = {
    web  = "10.20.1.0/24"
    data = "10.20.2.0/24"
  }

}

resource "azurerm_resource_group" "lab02" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "lab02" {
  name                = local.virtual_network_name
  location            = azurerm_resource_group.lab02.location
  resource_group_name = azurerm_resource_group.lab02.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "lab02" {
  for_each = local.subnets

  name                 = "snet-${each.key}"
  resource_group_name  = azurerm_resource_group.lab02.name
  virtual_network_name = azurerm_virtual_network.lab02.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-lab02-web"
  location            = azurerm_resource_group.lab02.location
  resource_group_name = azurerm_resource_group.lab02.name
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.lab02["web"].id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_storage_account" "lab02" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.lab02.name
  location                 = azurerm_resource_group.lab02.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}
