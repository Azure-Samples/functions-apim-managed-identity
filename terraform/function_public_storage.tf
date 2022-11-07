resource "azurerm_storage_account" "public" {
  name                     = "${replace(var.prefix, "-", "")}public"
  resource_group_name      = azurerm_resource_group.public.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_role_assignment" "public" {
  scope                = azurerm_storage_account.public.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.public.principal_id
}