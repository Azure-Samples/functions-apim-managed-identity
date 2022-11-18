/*
This key vault is used to store the app registration client secret for the private function app.
This avoids having to store the secret in plain text in the app settings.
*/
resource "azurerm_key_vault" "demo" {
  name                       = "${replace(var.prefix, "-", "")}private"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.private.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "Set", "List", "Delete"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.private.principal_id

    secret_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_key_vault_secret" "demo" {
  name         = "app-registration-client-secret"
  value        = azuread_application_password.function_private.value
  key_vault_id = azurerm_key_vault.demo.id
}