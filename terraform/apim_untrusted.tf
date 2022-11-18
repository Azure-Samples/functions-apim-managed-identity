/*
The API we will use to test an untrusted user assigned managed identity. 
*/
resource "azurerm_api_management_api" "untrusted" {
  name                = "untrusted"
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.demo.name
  revision            = "1"
  display_name        = "Untrusted API"
  path                = "untrusted"
  protocols           = ["https"]

  service_url = "https://${azurerm_windows_function_app.private.default_hostname}/api"
}

/*
The operation on our API that we will use to test an untrusted user assigned managed identity. 
*/
resource "azurerm_api_management_api_operation" "untrusted" {
  operation_id        = "test"
  api_name            = azurerm_api_management_api.untrusted.name
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

/*
This policy differs in that it uses our untrusted user assigned managed identity to get the token.
*/
resource "azurerm_api_management_api_operation_policy" "untrusted" {
  api_name            = azurerm_api_management_api_operation.untrusted.api_name
  api_management_name = azurerm_api_management_api_operation.untrusted.api_management_name
  resource_group_name = azurerm_api_management_api_operation.untrusted.resource_group_name
  operation_id        = azurerm_api_management_api_operation.untrusted.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <authentication-managed-identity resource="${azuread_application.function_private.application_id}" client-id="${azurerm_user_assigned_identity.apim_untrusted.client_id}" output-token-variable-name="msi-access-token" ignore-error="false"/>
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
    </set-header>
  </inbound>
</policies>
XML
}