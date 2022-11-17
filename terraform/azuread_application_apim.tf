/*
This is the AzureAD App Registration that is used to implement AzureAD authentication on our Private Function App.
The confiuration follows the instuctions found here: https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad
*/
resource "random_uuid" "apim_oauth" {}
resource "random_uuid" "apim_role" {}

resource "azuread_application" "apim" {
  display_name    = "${var.prefix}-apim"
  identifier_uris = ["api://${var.prefix}-apim"]

  web {
    redirect_uris = ["https://${var.prefix}-apim.azure-api.net/"]
    homepage_url  = "https://${var.prefix}-apim.azure-api.net"
    implicit_grant {
      id_token_issuance_enabled = false
      access_token_issuance_enabled = true
    }
  }
  api {

    oauth2_permission_scope {
      id                         = random_uuid.apim_oauth.result
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
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
  app_role {
    allowed_member_types = ["Application","User"]
    description          = "Example role."
    display_name         = "Example role"
    id                   = random_uuid.apim_role.result
    enabled              = true
    value                = "example"
  }
}

/*
The Enterprise Application that is part of the App Registration is set to require assigned users and we have assigned our trusted user assigned managed identity to it.
*/
resource "azuread_service_principal" "apim" {
  application_id               = azuread_application.apim.application_id
  app_role_assignment_required = true
  feature_tags {
    enterprise = true
  }
}

resource "azuread_app_role_assignment" "apim" {
  app_role_id         = azuread_service_principal.apim.app_role_ids["example"]
  principal_object_id = azuread_group.apim.object_id
  resource_object_id  = azuread_service_principal.apim.object_id
}

/*
The secret is required for the Private Function App to configure authentication.
*/
resource "time_rotating" "apim" {
  rotation_days = 7
}

resource "azuread_application_password" "apim" {
  application_object_id = azuread_application.apim.object_id
  display_name          = "${var.prefix}-app-secret"
  rotate_when_changed = {
    rotation = time_rotating.apim.id
  }
}