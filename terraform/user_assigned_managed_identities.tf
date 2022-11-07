resource "azurerm_user_assigned_identity" "apim" {
  location            = var.location
  name                = "${var.prefix}-apim"
  resource_group_name = azurerm_resource_group.apim.name
}

resource "azurerm_user_assigned_identity" "public" {
  location            = var.location
  name                = "${var.prefix}-public"
  resource_group_name = azurerm_resource_group.public.name
}

resource "azurerm_user_assigned_identity" "private" {
  location            = var.location
  name                = "${var.prefix}-private"
  resource_group_name = azurerm_resource_group.private.name
}