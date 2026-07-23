terraform {
  required_version = ">= 1.12.2"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.1.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 7.27.0, < 8.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.27.0, < 8.0.0"
    }
  }

}

provider "azuread" {
  tenant_id = var.entra_tenant_id
}
