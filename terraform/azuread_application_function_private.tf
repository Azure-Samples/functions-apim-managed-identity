/*
This is the AzureAD App Registration that is used to implement AzureAD authentication on our Private Function App.
The confiuration follows the instuctions found here: https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad
*/
locals {
  private_app_role_name = "Private.Example"
}

resource "random_uuid" "function_private_scope" {}
resource "random_uuid" "function_private_role" {}

resource "azuread_application" "function_private" {
  display_name = "${var.prefix}-function-private"

  web {
    redirect_uris = ["https://${var.prefix}-private.azurewebsites.net/.auth/login/aad/callback"]
    homepage_url  = "https://${var.prefix}-private.azurewebsites.net"
    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
  api {
    oauth2_permission_scope {
      id                         = random_uuid.function_private_scope.result
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

  app_role {
    allowed_member_types = ["Application","User"]
    description          = "Example role."
    display_name         = "Example role"
    id                   = random_uuid.function_private_role.result
    enabled              = true
    value                = local.private_app_role_name
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
resource "azuread_service_principal" "function_private" {
  application_id               = azuread_application.function_private.application_id
  app_role_assignment_required = true
  feature_tags {
    enterprise = true
    gallery    = false
  }
}

/*
Note although a managed identity (service principal) can be assigned to a group and the group can be assigned to an App Registration, this scenario is not currently supported.
As such, this group assignment currently has not effect in our example and the individual assignment `azuread_app_role_assignment.function_private_managed_identity` is required for the demo to function.
See this article for details: https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-add-app-roles-in-azure-ad-apps#declare-roles-for-an-application
"Currently, if you add a service principal to a group, and then assign an app role to that group, Azure AD doesn't add the roles claim to tokens it issues."
*/
resource "azuread_app_role_assignment" "function_private_group" {
  app_role_id         = azuread_service_principal.function_private.app_role_ids[local.private_app_role_name]
  principal_object_id = azuread_group.private.object_id
  resource_object_id  = azuread_service_principal.function_private.object_id
}


resource "azuread_app_role_assignment" "function_private_managed_identity" {
  app_role_id         = azuread_service_principal.function_private.app_role_ids[local.private_app_role_name]
  principal_object_id = azurerm_user_assigned_identity.apim.principal_id
  resource_object_id  = azuread_service_principal.function_private.object_id
}

/*
The secret is required for the Private Function App to configure authentication.
*/
resource "time_rotating" "function_private" {
  rotation_days = 7
}

resource "azuread_application_password" "function_private" {
  application_object_id = azuread_application.function_private.object_id
  display_name          = "${var.prefix}-app-secret"
  rotate_when_changed = {
    rotation = time_rotating.function_private.id
  }
}