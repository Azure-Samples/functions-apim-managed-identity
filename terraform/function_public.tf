/*
These are the public function apps that we will call APIM from.
There is a trusted and an untrusted version. Only the trusted version has it's managed identity client id in the APIM policy.
It include the app settings that are referenced as environment variables in the function app C# code.
`ApimKey` is the subscription key (API Key) used as an additional layer of security.
`ApimUrl` is the URL of our APIM operation.
`ClientId` is the client ID of our User Assigned Managed Identity. This is required by the code that generate the JWT token.
NOTE: We use our managed identity to connect to the storage too. See the `storage_uses_managed_identity` property.
*/
locals {
  public_function_path = "${path.root}/../src/Functions/PublicFunction"
}

resource "azurerm_service_plan" "public" {
  name                = "${var.prefix}-public"
  location            = var.location
  resource_group_name = azurerm_resource_group.public.name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_windows_function_app" "public_untrusted" {
  depends_on = [
    azurerm_windows_function_app.private
  ]
  name                = "${var.prefix}-public-untrusted"
  location            = var.location
  resource_group_name = azurerm_resource_group.public.name
  service_plan_id     = azurerm_service_plan.public.id

  storage_account_name          = azurerm_storage_account.public.name
  storage_uses_managed_identity = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.public_untrusted.id]
  }

  app_settings = {
    ApimKey                  = random_password.apim.result
    ApimUrl                  = azurerm_api_management.demo.gateway_url
    ClientId                 = azurerm_user_assigned_identity.public_untrusted.client_id
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  site_config {
    application_stack {
      dotnet_version = "6"
    }
  }

  provisioner "local-exec" {
    working_dir = local.public_function_path
    command     = format(local.powershell_deploy, azurerm_windows_function_app.public_untrusted.name)
    interpreter = ["PowerShell", "-Command"]
  }
}

resource "azurerm_windows_function_app" "public_trusted" {
  depends_on = [
    azurerm_windows_function_app.public_untrusted
  ]
  name                = "${var.prefix}-public-trusted"
  location            = var.location
  resource_group_name = azurerm_resource_group.public.name
  service_plan_id     = azurerm_service_plan.public.id

  storage_account_name          = azurerm_storage_account.public.name
  storage_uses_managed_identity = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.public_trusted.id]
  }

  app_settings = {
    ApimKey                  = random_password.apim.result
    ApimUrl                  = azurerm_api_management.demo.gateway_url
    ClientId                 = azurerm_user_assigned_identity.public_trusted.client_id
    TargetAppId              = azuread_application.apim.application_id
    TargetAppUri             = "api://${var.prefix}-apim"
    TenantId                 = data.azurerm_client_config.current.tenant_id
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  site_config {
    application_stack {
      dotnet_version = "6"
    }
  }

  provisioner "local-exec" {
    working_dir = local.public_function_path
    command     = format(local.powershell_deploy, azurerm_windows_function_app.public_trusted.name)
    interpreter = ["PowerShell", "-Command"]
  }
}