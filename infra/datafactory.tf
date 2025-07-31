resource "azurerm_data_factory" "adf" {
  name                = "adf-mlops-dev-26698"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  identity {
    type = "SystemAssigned"
  }
}