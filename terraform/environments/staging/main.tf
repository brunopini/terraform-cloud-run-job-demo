# Migrate Artifact Registry repository state =============================
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = "${var.project_id}-arr-${var.region_short}-docker"
  format        = "DOCKER"
}

# Cloud Run Job ==========================================================
resource "google_cloud_run_v2_job" "job" {
  name = "${var.project_id}-crj-${var.region_short}-demojob"
  location = var.region
  launch_stage = "BETA"

  template {
    template {
      containers {
        image = var.image_url

        env {
          name = "GOOGLE_APPLICATION_CREDENTIALS_JSON"
          value_source {
            secret_key_ref {
              secret = google_secret_manager_secret.external_usage_key.id
              version = "latest"
            }
          }
        }

        resources {
          limits = {
            cpu = "1"
            memory = "2Gi"
          }
        }
      }

      timeout = "180s"
      max_retries = 3

      service_account = google_service_account.job_sa.email

      vpc_access {
        network_interfaces {
          network = google_compute_network.vpc.name
          subnetwork = google_compute_subnetwork.subnet.name
        }
        egress = "PRIVATE_RANGES_ONLY"
      }
    }
    task_count = 1
  }

  lifecycle {
    ignore_changes = [
      launch_stage
    ]
  }
}

resource "google_service_account" "job_sa" {
  account_id   = "gsa-g-job"
  display_name = "gsa-g-job"
}

resource "google_artifact_registry_repository_iam_member" "artifact_registry_reader" {
  location = var.region
  project  = var.project_id
  repository = google_artifact_registry_repository.docker.repository_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.job_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.external_usage_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.job_sa.email}"
}

resource "google_compute_subnetwork_iam_member" "compute_network_user" {
  subnetwork = google_compute_subnetwork.subnet.name
  role       = "roles/compute.networkUser"
  region     = var.region
  member     = "serviceAccount:${google_service_account.job_sa.email}"
}

# Cloud Scheduler ========================================================
resource "google_cloud_scheduler_job" "scheduler" {
  name     = "${var.project_id}-sch-g-scheduler"
  region   = var.region
  schedule = var.job_schedule
  time_zone = "UTC"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = "${local.cloud_run_job_endpoint}/${var.project_id}/jobs/${google_cloud_run_v2_job.job.name}:run"
    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }
}

resource "google_service_account" "scheduler_sa" {
  account_id   = "gsa-g-scheduler"
  display_name = "gsa-g-scheduler"
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project = google_cloud_run_v2_job.job.project
  location = google_cloud_run_v2_job.job.location
  name = google_cloud_run_v2_job.job.name
  role = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Job Secrets ============================================================
resource "google_service_account" "external_usage" {
  account_id   = "gsa-g-external"
  display_name = "gsa-g-external"
}

resource "google_service_account_key" "external_usage" {
  service_account_id = google_service_account.external_usage.name
  private_key_type    = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "google_secret_manager_secret" "external_usage_key" {
  secret_id = "${var.project_id}-gsm-g-externalkey"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "external_usage_key" {
  secret      = google_secret_manager_secret.external_usage_key.id
  secret_data = google_service_account_key.external_usage.private_key
}
