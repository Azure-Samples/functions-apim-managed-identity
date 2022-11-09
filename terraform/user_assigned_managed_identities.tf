resource "azurerm_user_assigned_identity" "apim" {
  location            = var.location
  name                = "${var.prefix}-apim"
  resource_group_name = azurerm_resource_group.apim.name
}

resource "azurerm_user_assigned_identity" "apim_untrusted" {
  location            = var.location
  name                = "${var.prefix}-apim-untrusted"
  resource_group_name = azurerm_resource_group.apim.name
}

resource "azurerm_user_assigned_identity" "public_untrusted" {
  location            = var.location
  name                = "${var.prefix}-public-untrusted"
  resource_group_name = azurerm_resource_group.public.name
}

resource "azurerm_user_assigned_identity" "public_trusted" {
  location            = var.location
  name                = "${var.prefix}-public-trusted"
  resource_group_name = azurerm_resource_group.public.name
}

resource "azurerm_user_assigned_identity" "private" {
  location            = var.location
  name                = "${var.prefix}-private"
  resource_group_name = azurerm_resource_group.private.name
}