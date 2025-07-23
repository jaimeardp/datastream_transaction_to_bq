# ==============================================================================
# OUTPUT VALUES
# ==============================================================================

# PostgreSQL Instance Outputs
output "postgres_instance_name" {
  description = "Name of the PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.name
}

output "postgres_private_ip" {
  description = "Private IP address of PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.private_ip_address
}

output "postgres_public_ip" {
  description = "Public IP address of PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.public_ip_address
}

output "postgres_connection_name" {
  description = "Connection name for PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.connection_name
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = google_sql_database.ecommerce_database.name
}

output "postgres_self_link" {
  description = "Self link of the PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.self_link
}

# BigQuery Outputs
output "bigquery_analytics_dataset_id" {
  description = "BigQuery analytics dataset ID"
  value       = google_bigquery_dataset.ecommerce_analytics.dataset_id
}

output "bigquery_staging_dataset_id" {
  description = "BigQuery staging dataset ID"
  value       = google_bigquery_dataset.ecommerce_staging.dataset_id
}

output "bigquery_analytics_dataset_url" {
  description = "BigQuery analytics dataset URL"
  value       = "https://console.cloud.google.com/bigquery?project=${var.project_id}&ws=!1m4!1m3!3m2!1s${var.project_id}!2s${google_bigquery_dataset.ecommerce_analytics.dataset_id}"
}

# Datastream Outputs
output "datastream_stream_id" {
  description = "Datastream stream ID"
  value       = google_datastream_stream.postgres_to_bigquery.stream_id
}

output "datastream_stream_state" {
  description = "Datastream stream state"
  value       = google_datastream_stream.postgres_to_bigquery.state
}

output "datastream_stream_url" {
  description = "Datastream stream console URL"
  value       = "https://console.cloud.google.com/datastream/streams/locations/${var.region}/instances/${google_datastream_stream.postgres_to_bigquery.stream_id}?project=${var.project_id}"
}

output "postgres_source_profile_id" {
  description = "PostgreSQL source connection profile ID"
  value       = google_datastream_connection_profile.postgres_source.connection_profile_id
}

output "bigquery_destination_profile_id" {
  description = "BigQuery destination connection profile ID"
  value       = google_datastream_connection_profile.bigquery_destination.connection_profile_id
}

# Networking Outputs
output "vpc_network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "Subnet CIDR range"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

# SSL Certificate Outputs
output "postgres_client_cert" {
  description = "PostgreSQL client certificate"
  value       = google_sql_ssl_cert.client_cert.cert
  sensitive   = true
}

output "postgres_client_key" {
  description = "PostgreSQL client private key"
  value       = google_sql_ssl_cert.client_cert.private_key
  sensitive   = true
}

output "postgres_server_ca_cert" {
  description = "PostgreSQL server CA certificate"
  value       = google_sql_ssl_cert.client_cert.server_ca_cert
  sensitive   = true
}

# Monitoring Outputs
output "monitoring_dashboard_url" {
  description = "Monitoring dashboard URL"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.cdc_pipeline_dashboard.id}?project=${var.project_id}"
}

# Connection Commands
output "postgres_connection_command" {
  description = "Command to connect to PostgreSQL via public IP"
  value       = length(var.authorized_networks) > 0 ? "psql \"host=${google_sql_database_instance.postgres_instance.public_ip_address} dbname=${google_sql_database.ecommerce_database.name} user=postgres sslmode=require\"" : "No public access configured"
}

output "postgres_proxy_connection_command" {
  description = "Command to connect to PostgreSQL via Cloud SQL Proxy"
  value       = "gcloud sql connect ${google_sql_database_instance.postgres_instance.name} --user=postgres --database=${google_sql_database.ecommerce_database.name}"
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

# Summary Information
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment           = var.environment
    region               = var.region
    postgres_instance    = google_sql_database_instance.postgres_instance.name
    postgres_private_ip  = google_sql_database_instance.postgres_instance.private_ip_address
    postgres_public_ip   = google_sql_database_instance.postgres_instance.public_ip_address
    database_name        = google_sql_database.ecommerce_database.name
    analytics_dataset    = google_bigquery_dataset.ecommerce_analytics.dataset_id
    staging_dataset      = google_bigquery_dataset.ecommerce_staging.dataset_id
    datastream_stream    = google_datastream_stream.postgres_to_bigquery.stream_id
    datastream_state     = google_datastream_stream.postgres_to_bigquery.state
    vpc_network          = google_compute_network.vpc_network.name
  }
}

# Next Steps Instructions
output "next_steps" {
  description = "Next steps for completing the setup"
  value = [
    "1. Connect to PostgreSQL and run the database setup script",
    "2. Wait for Datastream to reach RUNNING state (check: terraform output datastream_stream_state)",
    "3. Verify data is flowing to BigQuery tables",
    "4. Create analytics views using the provided SQL scripts",
    "5. Set up monitoring alerts and dashboards",
    "Connection command: ${length(var.authorized_networks) > 0 ? "psql \"host=${google_sql_database_instance.postgres_instance.public_ip_address} dbname=${google_sql_database.ecommerce_database.name} user=postgres sslmode=require\"" : "gcloud sql connect ${google_sql_database_instance.postgres_instance.name} --user=postgres --database=${google_sql_database.ecommerce_database.name}"}"
  ]
}