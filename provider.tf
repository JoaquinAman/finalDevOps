
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }


  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "subscription_id"
  client_id       = "client_id"
  client_secret   = "client secret"
  tenant_id       = "tenant_id"
}