# ==============================================================================
# MONITORING AND ALERTING RESOURCES
# ==============================================================================

# Notification channel for alerts
resource "google_monitoring_notification_channel" "email" {
  count        = var.notification_email != "" ? 1 : 0
  display_name = "Email Notification Channel - ${var.environment}"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }

  enabled = true
}

# Alert policy for Datastream stream errors
# resource "google_monitoring_alert_policy" "datastream_stream_errors" {
#   count        = var.notification_email != "" ? 1 : 0
#   display_name = "Datastream Stream Errors - ${var.environment}"
#   combiner     = "OR"
#   enabled      = true

#   conditions {
#     display_name = "Datastream stream error rate"

#     condition_threshold {
#       # FIXED: Added a specific metric.type to the filter
#       filter = "metric.type=\"datastream.googleapis.com/stream/error_count\" AND resource.type=\"datastream.googleapis.com/Stream\" AND resource.labels.stream_id=\"${google_datastream_stream.postgres_to_bigquery.stream_id}\""
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0
#       duration        = "300s"

#       aggregations {
#         alignment_period     = "300s"
#         per_series_aligner   = "ALIGN_RATE"
#         cross_series_reducer = "REDUCE_SUM"
#         group_by_fields      = ["resource.label.stream_id"]
#       }
#     }
#   }

#   notification_channels = [
#     google_monitoring_notification_channel.email[0].id
#   ]

#   alert_strategy {
#     auto_close = "1800s"
#   }

#   depends_on = [google_project_service.required_apis]
# }

# Alert policy for Cloud SQL high CPU usage
resource "google_monitoring_alert_policy" "cloudsql_high_cpu" {
  count        = var.notification_email != "" ? 1 : 0
  display_name = "Cloud SQL High CPU - ${var.environment}"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Cloud SQL CPU utilization"

    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${google_sql_database_instance.postgres_instance.name}\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.database_id"]
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email[0].id
  ]

  alert_strategy {
    auto_close = "1800s"
  }

  depends_on = [google_project_service.required_apis]
}

# Alert policy for Cloud SQL high memory usage
resource "google_monitoring_alert_policy" "cloudsql_high_memory" {
  count        = var.notification_email != "" ? 1 : 0
  display_name = "Cloud SQL High Memory - ${var.environment}"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Cloud SQL Memory utilization"

    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${google_sql_database_instance.postgres_instance.name}\" AND metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      duration        = "300s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.database_id"]
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email[0].id
  ]

  alert_strategy {
    auto_close = "1800s"
  }

  depends_on = [google_project_service.required_apis]
}

# Dashboard for monitoring the CDC pipeline
resource "google_monitoring_dashboard" "cdc_pipeline_dashboard" {
  # REFACTORED: Dashboard JSON is now in a separate file for cleanliness
  dashboard_json = templatefile("${path.module}/cdc_dashboard.json", {
    var_environment = var.environment,
    var_project_id  = var.project_id,
    google_datastream_stream_postgres_to_bigquery_stream_id = google_datastream_stream.postgres_to_bigquery.stream_id,
    google_sql_database_instance_postgres_instance_name     = google_sql_database_instance.postgres_instance.name
  })

  depends_on = [google_project_service.required_apis]
}

# Log sink for Datastream logs to BigQuery
resource "google_logging_project_sink" "datastream_logs" {
  name        = "datastream-logs-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.ecommerce_staging.dataset_id}"

  filter = "resource.type=\"datastream.googleapis.com/Stream\" AND resource.labels.stream_id=\"${google_datastream_stream.postgres_to_bigquery.stream_id}\""

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant BigQuery Data Editor role to the log sink's writer identity
resource "google_bigquery_dataset_iam_member" "log_sink_writer" {
  dataset_id = google_bigquery_dataset.ecommerce_staging.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.datastream_logs.writer_identity
}