resource "azurerm_service_plan" "public" {
  name                = "${var.prefix}-public"
  location            = var.location
  resource_group_name = azurerm_resource_group.public.name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_windows_function_app" "public" {
  name                = "${var.prefix}-public"
  location            = var.location
  resource_group_name = azurerm_resource_group.public.name
  service_plan_id     = azurerm_service_plan.public.id

  storage_account_name          = azurerm_storage_account.public.name
  storage_uses_managed_identity = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.public.id]
  }

  app_settings = {
    ApimKey = random_password.apim.result
    ApimUrl = "${azurerm_api_management.demo.gateway_url}/demo/test"
    ClientId = azurerm_user_assigned_identity.public.client_id
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  site_config {
    application_stack {
      dotnet_version = "6"
    }
  }
}