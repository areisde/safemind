resource "azurerm_application_insights" "aml_appinsights" {
  name                = "appi-mlops-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  workspace_id = azurerm_log_analytics_workspace.central.id  # reuse LAW
  tags = { env = "dev" }
}
