/*
This is the AzureAD App Registration that is used to implement AzureAD authentication on our Private Function App.
The confiuration follows the instuctions found here: https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad
*/

resource "azuread_application" "function_public" {
  display_name    = "${var.prefix}-function-public"
  identifier_uris = ["api://${var.prefix}-function-public"]

  web {
    redirect_uris = ["https://${var.prefix}-function-public.azure-api.net/"]
    homepage_url  = "https://${var.prefix}-function-public.azure-api.net"
    implicit_grant {
      id_token_issuance_enabled = true
      access_token_issuance_enabled = true
    }
  }

  required_resource_access {
    resource_app_id = azuread_application.apim.application_id # The App Registration for API Management

    resource_access {
      id   = random_uuid.apim_role.result # `example` app role
      type = "Role"
    }
  }
}

/*
The Enterprise Application that is part of the App Registration is set to require assigned users and we have assigned our trusted user assigned managed identity to it.
*/
resource "azuread_service_principal" "function_public" {
  application_id               = azuread_application.function_public.application_id
  app_role_assignment_required = true
  feature_tags {
    enterprise = true
  }
}

resource "azuread_app_role_assignment" "function_public" {
  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = azuread_group.apim.object_id
  resource_object_id  = azuread_service_principal.function_public.object_id
}

resource "azuread_app_role_assignment" "function_public_test" {
  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = azurerm_user_assigned_identity.public_trusted.principal_id
  resource_object_id  = azuread_service_principal.function_public.object_id
}