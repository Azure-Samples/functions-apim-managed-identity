resource "azurerm_resource_group" "apim" {
  name     = "${var.prefix}-apim-rg"
  location = var.location
}

resource "azurerm_resource_group" "public" {
  name     = "${var.prefix}-public-rg"
  location = var.location
}

resource "azurerm_resource_group" "private" {
  name     = "${var.prefix}-private-rg"
  location = var.location
}