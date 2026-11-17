terraform {
  required_version = ">= 1.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.60.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      # The Arc machine is created by azcmagent (not by Terraform), so it is not in the state.
      # Without this, `terraform destroy` fails on the Azure RG that still contains it.
      prevent_deletion_if_contains_resources = false
    }
  }
  resource_provider_registrations = "none"
}

# Authenticates as the Arc onboarding Service Principal, only to validate its
# credentials at plan time (see preflight.tf). When the check is disabled, the
# credentials are left null and the provider falls back to the Azure CLI login,
# so `terraform destroy` still works after the SP or its secret is gone.
provider "azurerm" {
  alias = "arc_onboarding"
  features {}
  tenant_id                       = var.tenant_id
  subscription_id                 = var.subscription_id
  client_id                       = var.check_arc_sp_credentials ? var.arc_client_id : null
  client_secret                   = var.check_arc_sp_credentials ? var.arc_client_secret : null
  resource_provider_registrations = "none"
}

provider "azapi" {}