resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "spoke_ml" {
  name                = "vnet-spoke-ml"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_ml" {
  name                      = "hub-to-spoke-ml"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_ml.id
  allow_forwarded_traffic   = true
}
