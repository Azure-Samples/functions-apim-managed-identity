/*
This is the private function app that will server as our backend for APIM.
The private function is configured to use AzureAD Authentication via an App Registration. See `auth_settings`.
*/
resource "azurerm_service_plan" "private" {
  name                = "${var.prefix}-private"
  location            = var.location
  resource_group_name = azurerm_resource_group.private.name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_windows_function_app" "private" {
  name                = "${var.prefix}-private"
  location            = var.location
  resource_group_name = azurerm_resource_group.private.name
  service_plan_id     = azurerm_service_plan.private.id

  storage_account_name          = azurerm_storage_account.private.name
  storage_uses_managed_identity = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.private.id]
  }

  auth_settings {
    enabled = true
    active_directory {
      client_id                  = azuread_application.function_private.application_id
      client_secret_setting_name = "AZURE_AD_AUTH_CLIENT_SECRET" # We use an app setting to store a key vault reference.
    }
  }

  key_vault_reference_identity_id = azurerm_user_assigned_identity.private.id # This is required to access Key Vault with the User Assigned Managed Identity

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE    = "1"
    AZURE_AD_AUTH_CLIENT_SECRET = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.demo.name};SecretName=${azurerm_key_vault_secret.demo.name})" # This is a reference to the client_secret stored in key vault
  }

  site_config {
    application_stack {
      dotnet_version = "6"
    }
  }

  provisioner "local-exec" {
    working_dir = "${path.root}/../src/Functions/PrivateFunction"
    command     = format(local.powershell_deploy, azurerm_windows_function_app.private.name)
    interpreter = ["PowerShell", "-Command"]
  }
}