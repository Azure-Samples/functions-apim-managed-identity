/*
We use separate resource groups for each aspect of the solution to simulate a real world scenario.
*/
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