# ==============================================================================
# BIGQUERY RESOURCES
# ==============================================================================

resource "google_bigquery_dataset" "ecommerce_analytics" {
  dataset_id    = "ecommerce_analytics"
  friendly_name = "E-commerce Analytics Dataset"
  description   = "Dataset for e-commerce analytics from PostgreSQL CDC"
  location      = var.bigquery_location

#   default_table_expiration_ms = 3600000 * 24 * 365  # 1 year

  access {
    role          = "OWNER"
    user_by_email = data.google_client_openid_userinfo.me.email
  }

  access {
    role         = "READER"
    special_group = "projectReaders"
  }

  access {
    role         = "WRITER"
    special_group = "projectWriters"
  }

  labels = local.labels

  depends_on = [google_project_service.required_apis]
}

resource "google_bigquery_dataset" "ecommerce_staging" {
  dataset_id    = "ecommerce_staging"
  friendly_name = "E-commerce Staging Dataset"
  description   = "Staging dataset for CDC processing and transformations"
  location      = var.bigquery_location

#   default_table_expiration_ms = 3600000 * 24 * 30  # 30 days

  access {
    role          = "OWNER"
    user_by_email = data.google_client_openid_userinfo.me.email
  }

  access {
    role         = "READER"
    special_group = "projectReaders"
  }

  access {
    role         = "WRITER"
    special_group = "projectWriters"
  }

  labels = local.labels

  depends_on = [google_project_service.required_apis]
}

# ==============================================================================
# BIGQUERY TABLES
# ==============================================================================

resource "google_bigquery_table" "customers" {
  dataset_id          = google_bigquery_dataset.ecommerce_analytics.dataset_id
  table_id            = "customers"
  deletion_protection = var.enable_deletion_protection

  time_partitioning {
    type                     = "DAY"
    field                    = "created_at"
  }

  require_partition_filter = false


  clustering = ["customer_id"]

  labels = local.labels

  schema = jsonencode([
    {
      name = "customer_id"
      type = "INTEGER"
      mode = "REQUIRED"
    },
    {
      name = "email"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "first_name"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "last_name"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "phone"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "address"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "city"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "country"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "updated_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}

resource "google_bigquery_table" "products" {
  dataset_id          = google_bigquery_dataset.ecommerce_analytics.dataset_id
  table_id            = "products"
  deletion_protection = var.enable_deletion_protection

  time_partitioning {
    type                     = "DAY"
    field                    = "created_at"
  }
  require_partition_filter = false

  clustering = ["category", "product_id"]

  labels = local.labels

  schema = jsonencode([
    {
      name = "product_id"
      type = "INTEGER"
      mode = "REQUIRED"
    },
    {
      name = "product_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "category"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "price"
      type = "NUMERIC"
      mode = "NULLABLE"
    },
    {
      name = "stock_quantity"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "description"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "updated_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}

resource "google_bigquery_table" "orders" {
  dataset_id          = google_bigquery_dataset.ecommerce_analytics.dataset_id
  table_id            = "orders"
  deletion_protection = var.enable_deletion_protection

  time_partitioning {
    type                     = "DAY"
    field                    = "order_date"
  }
  require_partition_filter = false

  clustering = ["customer_id", "order_status"]

  labels = local.labels

  schema = jsonencode([
    {
      name = "order_id"
      type = "INTEGER"
      mode = "REQUIRED"
    },
    {
      name = "customer_id"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "order_date"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "total_amount"
      type = "NUMERIC"
      mode = "NULLABLE"
    },
    {
      name = "order_status"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "shipping_address"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "updated_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}

resource "google_bigquery_table" "order_items" {
  dataset_id          = google_bigquery_dataset.ecommerce_analytics.dataset_id
  table_id            = "order_items"
  deletion_protection = var.enable_deletion_protection

  time_partitioning {
    type                     = "DAY"
    field                    = "created_at"
  }
  require_partition_filter = false


  clustering = ["order_id", "product_id"]

  labels = local.labels

  schema = jsonencode([
    {
      name = "item_id"
      type = "INTEGER"
      mode = "REQUIRED"
    },
    {
      name = "order_id"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "product_id"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "quantity"
      type = "INTEGER"
      mode = "REQUIRED"
    },
    {
      name = "unit_price"
      type = "NUMERIC"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}

# ==============================================================================
# DATA SOURCE FOR CURRENT USER
# ==============================================================================

data "google_client_openid_userinfo" "me" {}