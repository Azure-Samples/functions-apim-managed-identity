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
      client_id     = azuread_application.demo.application_id
      client_secret = azuread_application_password.demo.value
    }
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  site_config {
    application_stack {
      dotnet_version = "6"
    }
  }
}
