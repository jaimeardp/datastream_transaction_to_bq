# ==============================================================================
# NETWORKING RESOURCES
# ==============================================================================

resource "google_compute_network" "vpc_network" {
  name                    = "cdc-vpc-${var.environment}"
  auto_create_subnetworks = false

  # labels = local.labels

  depends_on = [google_project_service.required_apis]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "cdc-subnet-${var.environment}"
  ip_cidr_range = var.network_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.0.0/16"
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.3.0.0"         # 👈 MUST match your VPC subnet
  prefix_length = 16
  network       = google_compute_network.vpc_network.id

  depends_on = [google_project_service.required_apis]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.required_apis]
}

# ==============================================================================
# FIREWALL RULES
# ==============================================================================

# CORRECTED: This rule now correctly allows traffic ONLY from the Datastream subnet.
resource "google_compute_firewall" "allow_datastream" {
  name    = "allow-datastream-${var.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  # Only the Datastream source CIDR is needed.
  source_ranges = [var.datastream_subnet_cidr]

  # target_tags = ["cloudsql-instance"]

  depends_on = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-${var.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389", "5432"]
  }

  allow {
    protocol = "icmp"
  }

  # Allow from main VPC subnet
  source_ranges = [var.network_cidr]

  depends_on = [google_compute_network.vpc_network]
}

# REMOVED: The overly broad "allow_internal_subnets" rule is no longer needed.
# A specific rule for Datastream is more secure.

resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check-${var.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server", "https-server"]

  depends_on = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh-${var.environment}"
  network = google_compute_network.vpc_network.name

  # This rule allows SSH traffic from Google's IAP service.
  # The IP range is provided by the error message for browser-based SSH.
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  description = "Allows SSH connections from the Google Cloud Console."
}
resource "google_compute_firewall" "allow_datastream_by_sa" {
  name    = "allow-datastream-by-sa-${var.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  # This allows the specific Datastream service account to connect.
  source_service_accounts = ["service-740043250466@gcp-sa-datastream.iam.gserviceaccount.com"]

  description = "Allows Datastream to connect to Cloud SQL via Private Path using its service account identity."
}


data "template_file" "startup_script" {
  template = file("${path.module}/proxy-startup-script.sh.tpl")
  vars = {
    db_ip   = google_sql_database_instance.postgres_instance.private_ip_address
    db_port = "5432"
  }
}

resource "google_compute_instance" "proxy_vm" {
  name         = "proxy-vm-${var.environment}"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  tags         = ["proxy-vm"] # We will use this tag for firewall rules
  
  # can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  // Use the rendered script from the template file
  metadata_startup_script = data.template_file.startup_script.rendered

  // The proxy needs to start after the database has its private IP
  depends_on = [google_sql_database_instance.postgres_instance]
}

resource "google_compute_firewall" "allow_datastream_to_proxy" {
  name    = "allow-datastream-to-proxy"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"] # Correct port for PostgreSQL
  }

  # This is the "Datastream private connectivity" IP range
  source_ranges = [var.datastream_subnet_cidr] 

  # This is MORE SECURE than "All Instances in the Network".
  # It applies the rule ONLY to our proxy VM.
  target_tags = ["proxy-vm"] 
}