resource "azurerm_monitor_diagnostic_setting" "kv_logs" {
  name                       = "diag-kv"
  target_resource_id         = azurerm_key_vault.mlops_kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_log { category = "AuditEvent" }
}

resource "azurerm_monitor_diagnostic_setting" "vnet_spoke_logs" {
  name                       = "diag-vnet-spoke"
  target_resource_id         = azurerm_virtual_network.spoke_ml.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id
  enabled_log { category = "VMProtectionAlerts" }
}

resource "azurerm_monitor_diagnostic_setting" "vnet_hub_logs" {
  name                       = "diag-vnet-hub"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id
  enabled_log { category = "VMProtectionAlerts" }
}
