resource "azurerm_machine_learning_workspace" "aml" {
  name                = "aml-mlops-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  public_network_access_enabled = false          # Private only
  key_vault_id                  = azurerm_key_vault.mlops_kv.id
  application_insights_id       = azurerm_application_insights.aml_appinsights.id
  storage_account_id = azurerm_storage_account.wsblob.id


  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.datalake_uami.id]
  }

  tags = { env = "dev" }
}