terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.99.0"
    }
  }
}

# Configuration of Terraform with Azure environment variables
provider "azurerm" {
  features { }
  client_id           = var.azure-client-id
  client_secret       = var.azure-client-secret
  subscription_id     = var.azure-subscription
  tenant_id           = var.azure-tenant
}