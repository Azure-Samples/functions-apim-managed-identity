/*
The API we will use to test that leverages an App Registration, so we can use groups. It is configured with a backend that points to our Private Function App.
*/
resource "azurerm_api_management_api" "trusted_group" {
  name                = "trusted-group"
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.demo.name
  revision            = "1"
  display_name        = "Trusted Group Auth API"
  path                = "trusted-group"
  protocols           = ["https"]

  service_url = "https://${azurerm_windows_function_app.private.default_hostname}/api"
}

/*
The operation on our API that we will use to test. This maps to the /test method on our Function App.
*/
resource "azurerm_api_management_api_operation" "trusted_group" {
  operation_id        = "test"
  api_name            = azurerm_api_management_api.trusted_group.name
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
This is the policy that will be applied to our operation.

We are using the `validate-jwt` policy as it does not require you to specify the application ID of the Managed Identity and instead can use the audience claim to validate the token.

The example includes two `audience` claims. Depending on which version (V1 or V2) you are using you may get either the application URI or the application ID in the JWT `aud` claim. Both are equally secure.

The example includes two `issuer` claims. Again, depending on which version (V1 or V2) you are using you may get either of these issuers. Both are equally secure.

The example includes the App Role claim in the `required-claims` section, but also shows how you could use an AzureAD group as a role claim instead if that is a preferred method. Group claims are always emitted as a GUID when using AzureAD groups.

NOTE: This policy could be applied at the API level instead of the individual operation.
*/
resource "azurerm_api_management_api_operation_policy" "trusted_group" {
  api_name            = azurerm_api_management_api_operation.trusted_group.api_name
  api_management_name = azurerm_api_management_api_operation.trusted_group.api_management_name
  resource_group_name = azurerm_api_management_api_operation.trusted_group.resource_group_name
  operation_id        = azurerm_api_management_api_operation.trusted_group.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid." require-scheme="Bearer">
     <openid-config url="https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0/.well-known/openid-configuration" />
     <audiences>
         <audience>api://${var.prefix}-apim</audience>
         <audience>${azuread_application.apim.application_id}</audience>
     </audiences>
     <issuers>
         <issuer>https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/</issuer>
         <issuer>https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0</issuer>
     </issuers>
     <required-claims>
         <claim name="roles" match="any">
             <value>${local.apim_app_role_name}</value>
             <value>${azuread_group.apim.object_id}</value>
         </claim>
     </required-claims>
    </validate-jwt> 
    <authentication-managed-identity resource="${azuread_application.function_private.application_id}" client-id="${azurerm_user_assigned_identity.apim.client_id}" output-token-variable-name="msi-access-token" ignore-error="false"/>
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
    </set-header>
  </inbound>
</policies>
XML
}