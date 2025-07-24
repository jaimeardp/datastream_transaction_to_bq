# ==============================================================================
# DATASTREAM RESOURCES
# ==============================================================================

# Private connection for Datastream
resource "google_datastream_private_connection" "private_connection" {
  display_name            = "Private Connection ${var.environment}"
  location                = var.region
  private_connection_id   = "private-conn-${var.environment}"

  vpc_peering_config {
    vpc    = google_compute_network.vpc_network.id
    subnet = var.datastream_subnet_cidr
  }

  labels = local.labels

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# PostgreSQL source connection profile - PRIVATE IP (Infrastructure is ready!)
resource "google_datastream_connection_profile" "postgres_source" {
  display_name          = "PostgreSQL E-commerce Source 2"
  location              = var.region
  connection_profile_id = "postgres-source-${var.environment}"

  postgresql_profile {
    hostname = google_compute_instance.proxy_vm.network_interface[0].network_ip
    port     = 5432
    username = google_sql_user.datastream_user.name
    password = var.datastream_password
    database = local.database_name # Default database for PostgreSQL
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.private_connection.id
  }

  labels = local.labels

  depends_on = [
    google_sql_user.datastream_user,
    google_datastream_private_connection.private_connection,
    # google_service_networking_connection.private_vpc_connection,
    google_compute_instance.proxy_vm
    # google_compute_firewall.allow_datastream,
    # google_compute_firewall.allow_internal_subnets
  ]
}

# BigQuery destination connection profile
resource "google_datastream_connection_profile" "bigquery_destination" {
  display_name          = "BigQuery E-commerce Destination"
  location              = var.region
  connection_profile_id = "bigquery-dest-${var.environment}"

  bigquery_profile {}

  labels = local.labels

  depends_on = [google_bigquery_dataset.ecommerce_analytics]
}

# Datastream stream
resource "google_datastream_stream" "postgres_to_bigquery" {
  display_name = "PostgreSQL to BigQuery CDC Stream"
  location     = var.region
  stream_id    = "postgres-cdc-${var.environment}"
  
  source_config {
    source_connection_profile = google_datastream_connection_profile.postgres_source.id
    
    postgresql_source_config {
      include_objects {
        postgresql_schemas {
          schema = "public"
          postgresql_tables {
            table = "customers"
          }
          postgresql_tables {
            table = "products"
          }
          postgresql_tables {
            table = "orders"
          }
          postgresql_tables {
            table = "order_items"
          }
        }
      }
      
      exclude_objects {
        postgresql_schemas {
          schema = "information_schema"
        }
        postgresql_schemas {
          schema = "pg_catalog"
        }
      }
      
      replication_slot = "datastream_slot_${var.environment}"
      publication      = "datastream_publication_${var.environment}"
    }
  }

destination_config {
    destination_connection_profile = google_datastream_connection_profile.bigquery_destination.id
    
    bigquery_destination_config {
      data_freshness = "60s"
      
      single_target_dataset {
        # CORRECTED: Use the format "project_id:dataset_id"
        dataset_id = "${var.project_id}:${google_bigquery_dataset.ecommerce_analytics.dataset_id}"
      }
    }
  }

  backfill_all {
    postgresql_excluded_objects {
      postgresql_schemas {
        schema = "information_schema"
      }
      postgresql_schemas {
        schema = "pg_catalog"
      }
    }
  }

  desired_state = "RUNNING"
  
  labels = local.labels

  depends_on = [
    google_datastream_connection_profile.postgres_source,
    google_datastream_connection_profile.bigquery_destination,
    google_bigquery_table.customers,
    google_bigquery_table.products,
    google_bigquery_table.orders,
    google_bigquery_table.order_items
  ]

  lifecycle {
    prevent_destroy = false
  }
}