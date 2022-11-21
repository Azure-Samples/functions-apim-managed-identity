/*
This is the AzureAD App Registration that is used to implement App Role based authentication for our Azure API Management.
*/
locals {
  apim_app_role_name = "Apim.Example"
}

resource "random_uuid" "apim_oauth" {}
resource "random_uuid" "apim_role" {}

resource "azuread_application" "apim" {
  display_name    = "${var.prefix}-apim"
  identifier_uris = ["api://${var.prefix}-apim"]

  api {
    requested_access_token_version = 2
  }

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
    value                = local.apim_app_role_name
  }

  optional_claims {
    access_token {
      name = "groups"
    }
    id_token {
      name = "groups"
    }
    saml2_token {
      name = "groups"
    }
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
    gallery = false
  }
}

/*
Note although a managed identity (service principal) can be assigned to a group and the group can be assigned to an App Registration, this scenario is not currently supported.
As such, this group assignment currently has not effect in our example and the individual assignment `azuread_app_role_assignment.apim_managed_identity_assignment` is required for the demo to function.
See this article for details: https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-add-app-roles-in-azure-ad-apps#declare-roles-for-an-application
"Currently, if you add a service principal to a group, and then assign an app role to that group, Azure AD doesn't add the roles claim to tokens it issues."
*/
resource "azuread_app_role_assignment" "apim_group_assignment" {
  app_role_id         = azuread_service_principal.apim.app_role_ids[local.apim_app_role_name]
  principal_object_id = azuread_group.apim.object_id
  resource_object_id  = azuread_service_principal.apim.object_id
}


resource "azuread_app_role_assignment" "apim_managed_identity_assignment" {
  app_role_id         = azuread_service_principal.apim.app_role_ids[local.apim_app_role_name]
  principal_object_id = azurerm_user_assigned_identity.public_trusted.principal_id
  resource_object_id  = azuread_service_principal.apim.object_id
}