output "resource_group" {
  value = azurerm_resource_group.lab02.name
}

output "virtual_network" {
  value = azurerm_virtual_network.lab02.name
}

output "subnet_ids" {
  value = {
    for name, subnet in azurerm_subnet.lab02 : name => subnet.id
  }
}

output "network_security_group" {
  value = azurerm_network_security_group.web.name
}

output "storage_account" {
  value = azurerm_storage_account.lab02.name
}

