resource "random_uuid" "widgets_scope_id" {}

resource "azuread_application" "demo" {
  display_name = "${var.prefix}-private"
  
  web {
    redirect_uris = ["https://${var.prefix}-private.azurewebsites.net/.auth/login/aad/callback"]
    homepage_url = "https://${var.prefix}-private.azurewebsites.net"
    implicit_grant {
        id_token_issuance_enabled = true
    }
  }
  api {
    oauth2_permission_scope {
        id = random_uuid.widgets_scope_id.result
        value = "user_impersonation"
        admin_consent_description = "Allow the application to access ${var.prefix}-private on behalf of the signed-in user."
        admin_consent_display_name = "Access ${var.prefix}-private"
        user_consent_description = "Allow the application to access ${var.prefix}-private on your behalf."
        user_consent_display_name = "Access ${var.prefix}-private"
    }
  }
}

resource "azuread_application_password" "demo" {
  application_object_id = azuread_application.demo.object_id
  display_name = "${var.prefix}-app-secret"

}