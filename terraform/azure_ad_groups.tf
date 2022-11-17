resource "azuread_group" "apim" {
  display_name     = "${var.prefix}-apim"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true
}

resource "azuread_group_member" "apim" {
  group_object_id  = azuread_group.apim.id
  member_object_id = azurerm_user_assigned_identity.public_trusted.principal_id
}