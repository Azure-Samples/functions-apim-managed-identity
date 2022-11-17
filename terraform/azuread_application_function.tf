/*
This is the AzureAD App Registration that is used to implement AzureAD authentication on our Private Function App.
The confiuration follows the instuctions found here: https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad
*/
resource "random_uuid" "function" {}

resource "azuread_application" "function" {
  display_name = "${var.prefix}-private-function"

  web {
    redirect_uris = ["https://${var.prefix}-private.azurewebsites.net/.auth/login/aad/callback"]
    homepage_url  = "https://${var.prefix}-private.azurewebsites.net"
    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
  api {
    oauth2_permission_scope {
      id                         = random_uuid.function.result
      value                      = "user_impersonation"
      admin_consent_description  = "Allow the application to access ${var.prefix}-private on behalf of the signed-in user."
      admin_consent_display_name = "Access ${var.prefix}-private"
      user_consent_description   = "Allow the application to access ${var.prefix}-private on your behalf."
      user_consent_display_name  = "Access ${var.prefix}-private"
    }
  }
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
      type = "Role"
    }
  }
}

/*
The Enterprise Application that is part of the App Registration is set to require assigned users and we have assigned our trusted user assigned managed identity to it.
*/
resource "azuread_service_principal" "function" {
  application_id               = azuread_application.function.application_id
  app_role_assignment_required = true
  feature_tags {
    enterprise = true
    gallery    = true
  }
}

resource "azuread_app_role_assignment" "function" {
  app_role_id         = "00000000-0000-0000-0000-000000000000" # Default role
  principal_object_id = azurerm_user_assigned_identity.apim.principal_id
  resource_object_id  = azuread_service_principal.function.object_id
}

/*
The secret is required for the Private Function App to configure authentication.
*/
resource "time_rotating" "function" {
  rotation_days = 7
}

resource "azuread_application_password" "function" {
  application_object_id = azuread_application.function.object_id
  display_name          = "${var.prefix}-app-secret"
  rotate_when_changed = {
    rotation = time_rotating.function.id
  }
}