resource "azurerm_key_vault" "mlops_kv" {
  name                        = "kv-mlops-dev-26698"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
  enable_rbac_authorization   = true

  # Later: add a Private Endpoint. For now you can leave network_rules empty.
}

resource "azurerm_role_assignment" "kv_admin_me" {
  scope                = azurerm_key_vault.mlops_kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}


resource "azurerm_key_vault_key" "cmk" {
  name         = "cmk-mlops-storage"
  key_vault_id = azurerm_key_vault.mlops_kv.id
  key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]
  key_type     = "RSA"
  key_size     = 4096
  depends_on   = [azurerm_role_assignment.kv_admin_me]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after = "P365D"
    notify_before_expiry = "P60D"
  }
}

resource "azurerm_log_analytics_workspace" "central" {
  name                = "law-mlops-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

data "azurerm_client_config" "current" {}


