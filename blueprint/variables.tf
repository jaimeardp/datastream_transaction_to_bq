# ==============================================================================
# VARIABLES DEFINITION
# ==============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-east4", "us-west1", "us-west2", "us-west3", "us-west4",
      "europe-west1", "europe-west2", "europe-west3", "europe-west4", "europe-west6",
      "asia-east1", "asia-northeast1", "asia-southeast1", "australia-southeast1"
    ], var.region)
    error_message = "Region must be a valid GCP region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "postgres_password" {
  description = "Password for PostgreSQL root user"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.postgres_password) >= 8
    error_message = "PostgreSQL password must be at least 8 characters long."
  }
}

variable "datastream_password" {
  description = "Password for Datastream user"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.datastream_password) >= 8
    error_message = "Datastream password must be at least 8 characters long."
  }
}

variable "authorized_networks" {
  description = "List of authorized networks for Cloud SQL"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "postgres_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-custom-2-8192"
}

variable "postgres_disk_size" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.postgres_disk_size >= 10 && var.postgres_disk_size <= 1000
    error_message = "Disk size must be between 10 and 1000 GB."
  }
}

variable "postgres_backup_enabled" {
  description = "Enable automated backups for PostgreSQL"
  type        = bool
  default     = true
}

variable "postgres_ha_enabled" {
  description = "Enable high availability for PostgreSQL"
  type        = bool
  default     = false
}

variable "bigquery_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
  validation {
    condition = contains([
      "US", "EU", "asia-east1", "asia-northeast1", "asia-southeast1",
      "australia-southeast1", "europe-west1", "europe-west2", "us-central1", "us-east1"
    ], var.bigquery_location)
    error_message = "BigQuery location must be a valid location."
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for resources"
  type        = bool
  default     = false
}

variable "network_cidr" {
  description = "CIDR block for VPC network"
  type        = string
  default     = "10.0.0.0/24"
}

variable "datastream_subnet_cidr" {
  description = "CIDR block for Datastream private connection"
  type        = string
  default     = "10.2.0.0/29"
}

variable "notification_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = ""
}