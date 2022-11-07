resource "azurerm_api_management" "demo" {
  name                = "${var.prefix}-apim"
  location            = var.location
  resource_group_name = azurerm_resource_group.apim.name
  publisher_name      = "Microsoft"
  publisher_email     = "demo@microsoft.com"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apim.id]
  }

  sku_name = "Developer_1"
}

resource "random_password" "apim" {
  length  = 32
  special = false
}

resource "azurerm_api_management_subscription" "demo" {
  api_management_name = azurerm_api_management.demo.name
  resource_group_name = azurerm_resource_group.apim.name
  primary_key         = random_password.apim.result
  state               = "active"
  display_name        = "Demo API"
}

resource "azurerm_api_management_api" "demo" {
  name                = "demo"
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.demo.name
  revision            = "1"
  display_name        = "Demo API"
  path                = "demo"
  protocols           = ["https"]

  service_url = "https://${azurerm_windows_function_app.private.default_hostname}/api"
}

resource "azurerm_api_management_api_operation" "demo" {
  operation_id        = "user-delete"
  api_name            = azurerm_api_management_api.demo.name
  api_management_name = azurerm_api_management.demo.name
  resource_group_name = azurerm_resource_group.apim.name
  display_name        = "Test Operation"
  method              = "GET"
  url_template        = "/test"
  description         = "Get test data from the private function."

  response {
    status_code = 200
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_api_management_api_operation_policy" "example" {
  api_name            = azurerm_api_management_api_operation.demo.api_name
  api_management_name = azurerm_api_management_api_operation.demo.api_management_name
  resource_group_name = azurerm_api_management_api_operation.demo.resource_group_name
  operation_id        = azurerm_api_management_api_operation.demo.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid." require-scheme="Bearer">
     <openid-config url="https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0/.well-known/openid-configuration" />
     <required-claims>
        <claim name="appid">
          <value>${azurerm_user_assigned_identity.public.client_id}</value>
        </claim>
      </required-claims>
    </validate-jwt> 
  </inbound>
</policies>
XML

}