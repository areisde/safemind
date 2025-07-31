resource "azurerm_storage_account" "datalake" {
  name                     = "stmlopsdev26698"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true                      # ADLS Gen2
  public_network_access_enabled = false                # no public internet
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.datalake_uami.id]
  }

  customer_managed_key {
    key_vault_key_id        = azurerm_key_vault_key.cmk.id
    user_assigned_identity_id = azurerm_user_assigned_identity.datalake_uami.id 
  }

  blob_properties {
    delete_retention_policy { days = 7 }
  }
}


resource "azurerm_storage_account" "wsblob" {
  name                     = "stamlws26698"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name

  account_tier             = "Standard"
  account_replication_type = "LRS"
  # HNS disabled → OK for AML workspace
  is_hns_enabled           = false

  public_network_access_enabled = false              # keep private
  https_traffic_only_enabled    = true

  identity {                                          # give it the same UAMI
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.datalake_uami.id]
  }

  customer_managed_key {                              # reuse your CMK
    key_vault_key_id          = azurerm_key_vault_key.cmk.id
    user_assigned_identity_id = azurerm_user_assigned_identity.datalake_uami.id
  }

  tags = { env = "dev" }
}
