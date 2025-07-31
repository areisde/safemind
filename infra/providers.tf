terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"          # the RG you just made
    storage_account_name = "tfstorageaccount26698"
    container_name       = "state"
    key                  = "hubspoke.tfstate"    # file name in the container
  }
}

provider "azurerm" {
  features {}
}
