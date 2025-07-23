# Real-Time CDC Pipeline: PostgreSQL to BigQuery with Datastream

This project implements a real-time Change Data Capture (CDC) pipeline on Google Cloud Platform (GCP). It uses Terraform to provision the necessary infrastructure to replicate data from a PostgreSQL database (Cloud SQL) to a data warehouse in BigQuery, using Datastream as the replication service.

The architecture is designed to be secure and robust, utilizing a private VPC and a reverse proxy pattern to enable communication between Google's managed services.

## Architecture

The pipeline consists of the following main components:

1.  **Cloud SQL for PostgreSQL:** Acts as the transactional source database (OLTP).
2.  **Datastream:** The CDC service that captures changes (INSERT, UPDATE, DELETE) from the source database.
3.  **BigQuery:** The destination data warehouse where data is replicated for analysis.
4.  **Private VPC and Subnets:** Provide a secure and isolated network environment for all resources.
5.  **Reverse Proxy VM:** A Compute Engine virtual machine that acts as a secure intermediary, allowing Datastream (in its own Google-managed network) to connect to the private Cloud SQL instance.
6.  **Cloud Monitoring:** Provides dashboards and alerts to monitor the health and performance of the pipeline.

## Prerequisites

Before deploying the infrastructure, ensure you have the following:

* A Google Cloud account with an active project and billing enabled.
* The Google Cloud SDK (`gcloud`) installed and authenticated on your local machine.
* Terraform (version 1.0 or higher) installed on your local machine.
* An SQL client (like DBeaver, pgAdmin, or `psql`) to connect to the PostgreSQL database.

## Setup and Deployment

Follow these steps to configure and deploy the complete pipeline.

### 1. Clone the Repository

Clone this project repository to your local machine.

```bash
git clone <your-repository-url>
cd <repository-directory>
```

### 2. Configure Terraform Variables

Copy the example variables file to create your own.

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit the `terraform.tfvars` file to set your `project_id` and secure passwords for the database.

**`terraform.tfvars`**
```hcl
project_id = "your-gcp-project-id"
postgres_password   = "YourSecurePostgresPassword123!"
datastream_password = "YourSecureDatastreamPassword123!"
notification_email  = "your-email@example.com"
```

### 3. Deploy the Infrastructure

Initialize Terraform and apply the configuration. This will provision all the necessary GCP resources, which may take several minutes.

```bash
terraform init
terraform apply
```

### 4. Prepare the PostgreSQL Database

Once the infrastructure is deployed, you need to prepare the source database.

1.  **Connect to the Database:** The most secure way to connect is through the proxy VM created by Terraform.
    * First, SSH into the proxy VM from your terminal:
        ```bash
        gcloud compute ssh proxy-vm-dev --zone <your-vm-zone>
        ```
        *(e.g., `us-central1-a`)*
    * From within the proxy VM, connect to the database using `psql`. You may need to install it first (`sudo apt-get update && sudo apt-get install postgresql-client -y`). Use the private IP of your Cloud SQL instance, which can be found in the Terraform output or the GCP console.
        ```bash
        psql -h <CLOUDSQL_PRIVATE_IP> -U postgres -d ecommerce_db
        ```

2.  **Run the Setup Script:** Execute the SQL script provided in `database_setup.sql` to create the tables, insert sample data, and configure the necessary replication permissions for the `datastream_user`.

### 5. Verify the Pipeline

After the database is prepared and the Datastream stream shows a `RUNNING` status:

1.  **Check BigQuery Data:** Navigate to BigQuery in the Google Cloud console. Verify that the tables (`customers`, `products`, etc.) have been created in the `ecommerce_analytics` dataset and contain the sample data.
2.  **Test CDC:** Make a change in the PostgreSQL database and watch for it to appear in BigQuery within a few minutes.
    ```sql
    UPDATE public.products SET price = 2399.99 WHERE product_name = 'MacBook Pro 16"';
    ```
3.  **Review Monitoring Dashboard:** Go to Cloud Monitoring in the GCP console and find the "CDC Pipeline Dashboard" to view performance metrics for the pipeline.

## Cleanup

To avoid ongoing charges, destroy all the infrastructure created by Terraform when you are finished.

```bash
terraform destroy
