/*
These are the storage accounts used to store the Function App code.
Because we are using a managed identity to connect to the storage (see the `storage_uses_managed_identity` property on the function app), we also provide a role assignment to the identity.
More details on the role can be found here: https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob#connecting-to-host-storage-with-an-identity-preview
*/
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

resource "azurerm_storage_account" "public" {
  name                     = "${replace(var.prefix, "-", "")}public"
  resource_group_name      = azurerm_resource_group.public.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_role_assignment" "public_untrusted" {
  scope                = azurerm_storage_account.public.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.public_untrusted.principal_id
}

resource "azurerm_role_assignment" "public_trusted" {
  scope                = azurerm_storage_account.public.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.public_trusted.principal_id
}