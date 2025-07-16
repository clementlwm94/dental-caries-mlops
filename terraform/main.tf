# Simple Google Cloud MLOps Infrastructure
# Clean, single-cloud architecture using Google Cloud Platform

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Google Cloud Provider
provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
}

# Variables
variable "gcp_project_id" {
  description = "Your GCP project ID"
  type        = string
}

variable "db_password" {
  description = "Database password for MLflow"
  type        = string
  sensitive   = true
}

# Enable required APIs
resource "google_project_service" "sqladmin" {
  project = var.gcp_project_id
  service = "sqladmin.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project = var.gcp_project_id
  service = "storage.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project = var.gcp_project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

# 1. Service Account for MLflow with proper permissions
resource "google_service_account" "mlflow_sa" {
  account_id   = "mlflow-service-account"
  display_name = "MLflow Service Account"
  description  = "Service account for MLflow server operations"

  depends_on = [google_project_service.run]
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "mlflow_cloudsql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.mlflow_sa.email}"

  depends_on = [google_service_account.mlflow_sa]
}

resource "google_project_iam_member" "mlflow_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.mlflow_sa.email}"

  depends_on = [google_service_account.mlflow_sa]
}

# 2. Google Cloud Storage bucket for MLflow artifacts
resource "google_storage_bucket" "mlflow_artifacts" {
  name          = "mlops-clement-artifacts"
  location      = "US"
  force_destroy = true

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  depends_on = [google_project_service.storage]
}

# 3. Google Cloud SQL PostgreSQL for MLflow
resource "google_sql_database_instance" "mlflow_postgres" {
  name             = "mlflow-postgres"
  database_version = "POSTGRES_17"
  region           = "us-central1"

  depends_on = [google_project_service.sqladmin]

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "allow-all"
      }
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "mlflow_db" {
  name     = "mlflowdb"
  instance = google_sql_database_instance.mlflow_postgres.name
  depends_on = [google_sql_database_instance.mlflow_postgres]
}

resource "google_sql_user" "mlflow_user" {
  name     = "mlflowuser"
  instance = google_sql_database_instance.mlflow_postgres.name
  password = var.db_password
  depends_on = [google_sql_database_instance.mlflow_postgres]
}

# 4. Google Cloud Run service for MLflow server
resource "google_cloud_run_service" "mlflow_server" {
  name     = "mlflow-server"
  location = "us-central1"

  template {
    spec {
      service_account_name = google_service_account.mlflow_sa.email

      containers {
        image = "gcr.io/${var.gcp_project_id}/mlflow-server:latest"

        ports {
          container_port = 5000
        }

        env {
          name  = "MLFLOW_BACKEND_STORE_URI"
          value = "postgresql://mlflowuser:${var.db_password}@${google_sql_database_instance.mlflow_postgres.public_ip_address}:5432/mlflowdb"
        }

        env {
          name  = "MLFLOW_DEFAULT_ARTIFACT_ROOT"
          value = "gs://${google_storage_bucket.mlflow_artifacts.name}/artifacts"
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.gcp_project_id
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_sql_database.mlflow_db,
    google_sql_user.mlflow_user,
    google_service_account.mlflow_sa,
    google_project_service.run
  ]
}

# Allow unauthenticated access to MLflow server
resource "google_cloud_run_service_iam_policy" "mlflow_server_policy" {
  location = google_cloud_run_service.mlflow_server.location
  service  = google_cloud_run_service.mlflow_server.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

# 5. GCP Cloud Run for Prediction Service


resource "google_cloud_run_service" "prediction_service" {
  name     = "dental-prediction"
  location = "us-central1"

  template {
    spec {
      service_account_name = google_service_account.mlflow_sa.email

      containers {
        image = "gcr.io/${var.gcp_project_id}/dental-prediction:latest"

        ports {
          container_port = 9696
        }

        env {
          name  = "MLFLOW_TRACKING_URI"
          value = "https://mlflow-server-${data.google_project.current.number}.us-central1.run.app"
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_service_account.mlflow_sa,
    google_project_service.run
  ]
}

# Allow unauthenticated access to Prediction Service
resource "google_cloud_run_service_iam_policy" "prediction_service_policy" {
  location = google_cloud_run_service.prediction_service.location
  service  = google_cloud_run_service.prediction_service.name

  policy_data = data.google_iam_policy.noauth.policy_data
}


data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Get current project info for predictable URLs
data "google_project" "current" {
  project_id = var.gcp_project_id
}

# Outputs
output "mlflow_url" {
  description = "MLflow tracking server URL"
  value       = google_cloud_run_service.mlflow_server.status[0].url
}

output "mlflow_server_url" {
  description = "MLflow server URL"
  value       = google_cloud_run_service.mlflow_server.status[0].url
}


output "prediction_service_url" {
  description = "Prediction service URL"
  value = google_cloud_run_service.prediction_service.status[0].url
}

output "postgres_endpoint" {
  value = "${google_sql_database_instance.mlflow_postgres.public_ip_address}:5432"
}

output "gcs_bucket" {
  value = "gs://${google_storage_bucket.mlflow_artifacts.name}"
}

output "predicted_mlflow_url" {
  description = "Predicted MLflow URL used by prediction service"
  value = "https://mlflow-server-${data.google_project.current.number}.us-central1.run.app"
}
