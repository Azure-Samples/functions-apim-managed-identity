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
      id_token_issuance_enabled = true
      access_token_issuance_enabled = true
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