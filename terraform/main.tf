terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.30.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.30.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}

/*
This data source is used to retrieve information about the account that the azurerm provider has been configured with.
In this case we are using it to retrive the Azure Tenant ID.
*/
data "azurerm_client_config" "current" {}