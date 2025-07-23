# ==============================================================================
# MAIN TERRAFORM CONFIGURATION
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# ==============================================================================
# PROVIDERS
# ==============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  instance_name = "postgres-cdc-${var.environment}"
  database_name = "ecommerce_db"
  labels = {
    environment = var.environment
    project     = "cdc-demo"
    managed-by  = "terraform"
  }
}

# ==============================================================================
# ENABLE APIS
# ==============================================================================

resource "google_project_service" "required_apis" {
  for_each = toset([
    "sqladmin.googleapis.com",
    "datastream.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}