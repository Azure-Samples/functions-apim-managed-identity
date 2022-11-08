/*
The APIM instance with basic settings and a User Assigned Managed Identity.
NOTE: This can take over 60 minutes to deploy
*/
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

/*
Key used for the subscription (API KEY)
*/
resource "random_password" "apim" {
  length  = 32
  special = false
}

/*
The subscription used to secure our API (API KEY).
NOTE: This is optional and just acts as an extra layer of protection outside of our JWT token.
*/
resource "azurerm_api_management_subscription" "demo" {
  api_management_name = azurerm_api_management.demo.name
  resource_group_name = azurerm_resource_group.apim.name
  primary_key         = random_password.apim.result
  state               = "active"
  display_name        = "Demo API"
}

/*
The API we will use to test. It is configured with a backend that points to our Private Function App.
*/
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

/*
The operation on our API that we will use to test. This maps to the /test method on our Function App.
*/
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

/*
This data source is used to retrieve information about the account that the azurerm provider has been configured with.
In this case we are using it to retrive the Azure Tenant ID for the operation policy.
*/
data "azurerm_client_config" "current" {}

/*
This is the policy that will be applied to our operation.
We use the `validate-azure-ad-token` policy to validate the JWT token that is passed in the Authorization Bearer header. 
This policy uses the Authorization Bearer header by default, but can be customised if needed.
We specifiy the Client ID of the User Assigned Managed Identity that we created for our Public Azure Function App in the `client-apllication-ids` list.
Further details on the policy can be found here: https://learn.microsoft.com/en-us/azure/api-management/api-management-access-restriction-policies#ValidateAAD
NOTE: This policy could be applied at the API level instead of the individual operation.
*/
resource "azurerm_api_management_api_operation_policy" "example" {
  api_name            = azurerm_api_management_api_operation.demo.api_name
  api_management_name = azurerm_api_management_api_operation.demo.api_management_name
  resource_group_name = azurerm_api_management_api_operation.demo.resource_group_name
  operation_id        = azurerm_api_management_api_operation.demo.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <validate-azure-ad-token tenant-id="${data.azurerm_client_config.current.tenant_id}">
      <client-application-ids>
          <application-id>${azurerm_user_assigned_identity.public_trusted.client_id}</application-id>
      </client-application-ids>
    </validate-azure-ad-token>
  </inbound>
</policies>
XML
}