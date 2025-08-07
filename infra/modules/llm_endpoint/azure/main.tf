terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}

# Resource Group for Azure OpenAI
resource "azurerm_resource_group" "aoai" {
  name     = "rg-${var.name}-aoai"
  location = var.location

  tags = var.tags
}

# Azure OpenAI Service
resource "azurerm_cognitive_account" "aoai" {
  name                = "aoai-${var.name}-${var.suffix}"
  location            = azurerm_resource_group.aoai.location
  resource_group_name = azurerm_resource_group.aoai.name
  kind                = "OpenAI"
  sku_name           = "S0"

  # Enable custom subdomain for API access
  custom_subdomain_name = "aoai-${var.name}-${var.suffix}"

  # Allow public access for now
  public_network_access_enabled = true

  tags = var.tags
}

# GPT-4o Model Deployment
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = var.gpt4o_deployment_name
  cognitive_account_id = azurerm_cognitive_account.aoai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = var.gpt4o_version
  }

  scale {
    type     = "GlobalStandard"
    capacity = var.gpt4o_capacity
  }

  rai_policy_name = "Microsoft.Default"
}
