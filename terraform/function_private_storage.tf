resource "azurerm_storage_account" "private" {
  name                     = "${replace(var.prefix, "-", "")}private"
  resource_group_name      = azurerm_resource_group.private.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_role_assignment" "private" {
  scope                = azurerm_storage_account.private.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.private.principal_id
}