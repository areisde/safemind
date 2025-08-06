resource "azurerm_resource_group" "rg" {
  name     = "${var.name}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, 0)]
}

output "subnet_id" {
  value = azurerm_subnet.workload.id
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}