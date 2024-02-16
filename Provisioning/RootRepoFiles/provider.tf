terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.53.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
  }

  backend "azurerm" {
    storage_account_name = "opsterraformstorage"
    container_name       = "tfstate"
    key                  = "singleregion.xio.tfstate"
    access_key           = "xx"
  }

  required_version = "~>1.4.0"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    api_management {
      purge_soft_delete_on_destroy = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }

    application_insights {
      disable_generated_rule = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  # subscription_id = "a2ed6818-cb69-41c7-a57a-f109f539c583"
  client_id     = "xxx"
  client_secret = var.client_secret
  tenant_id     = "xx"
}



provider "azuread" {
  client_id     = "xx"
  client_secret = var.client_secret
  tenant_id     = "x"
}