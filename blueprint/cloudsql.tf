# ==============================================================================
# CLOUD SQL POSTGRESQL RESOURCES
# ==============================================================================

resource "google_sql_database_instance" "postgres_instance" {
  name             = local.instance_name
  database_version = "POSTGRES_16"
  region           = var.region
  
  settings {
    tier                        = var.postgres_tier
    disk_size                   = var.postgres_disk_size
    disk_type                   = "PD_SSD"
    disk_autoresize            = true
    disk_autoresize_limit      = var.postgres_disk_size * 5
    availability_type          = var.postgres_ha_enabled ? "REGIONAL" : "ZONAL"
    deletion_protection_enabled = var.enable_deletion_protection

    backup_configuration {
      enabled                        = var.postgres_backup_enabled
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = var.postgres_backup_enabled
      transaction_log_retention_days = 7
      
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7  # Sunday
      hour         = 4  # 4 AM
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
    # MINIMAL CONFIGURATION - Only essential CDC flag
    database_flags {
      name  = "cloudsql.logical_decoding"
      value = "on"
    }

    # Note: When cloudsql.logical_decoding=on is set:
    # - wal_level is automatically set to 'logical'
    # - max_replication_slots defaults to 10 (sufficient for Datastream)  
    # - max_wal_senders defaults to 10 (sufficient for Datastream)

    ip_configuration {
      ipv4_enabled                                  = length(var.authorized_networks) > 0
      private_network                               = google_compute_network.vpc_network.id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = false
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }
    user_labels = local.labels
  }

  deletion_protection = var.enable_deletion_protection

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.required_apis
  ]
}

# ==============================================================================
# DATABASE AND USERS
# ==============================================================================

resource "google_sql_database" "ecommerce_database" {
  name     = local.database_name
  instance = google_sql_database_instance.postgres_instance.name
  
  depends_on = [google_sql_database_instance.postgres_instance]
}

resource "google_sql_user" "postgres_root" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres_instance.name
  password = var.postgres_password
  
  depends_on = [google_sql_database_instance.postgres_instance]
}

resource "google_sql_user" "datastream_user" {
  name     = "datastream_user"
  instance = google_sql_database_instance.postgres_instance.name
  password = var.datastream_password
  
  depends_on = [google_sql_database_instance.postgres_instance]
}

# ==============================================================================
# SSL CERTIFICATES
# ==============================================================================

resource "google_sql_ssl_cert" "client_cert" {
  common_name = "client-cert-${var.environment}"
  instance    = google_sql_database_instance.postgres_instance.name
  
  depends_on = [google_sql_database_instance.postgres_instance]
}