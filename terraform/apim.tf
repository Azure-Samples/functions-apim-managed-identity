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
    identity_ids = [azurerm_user_assigned_identity.apim.id, azurerm_user_assigned_identity.apim_untrusted.id]
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