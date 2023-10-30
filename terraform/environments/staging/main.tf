resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-sbn-${var.region_short}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.name
}

resource "google_compute_firewall" "firewall_egress" {
  name    = "${var.project_id}-fwe-${var.region_short}-vpcegress"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  destination_ranges = ["0.0.0.0/0"]

  direction = "EGRESS"
}

resource "google_compute_router" "router" {
  name    = "${var.project_id}-rtr-g-vpcrouter"
  region  = var.region
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat-${var.region_short}-sbnnat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_storage_bucket" "audience_data" {
  name     = "${var.project_id}-gcs-${var.region_short}-audiences"
  location = var.region
}

resource "google_cloud_run_v2_job" "uploader" {
  name = "${var.project_id}-crj-${var.region_short}-uploader"
  location = var.region
  launch_stage = "BETA"

  template {
    template {
      containers {
        image = var.image_uri

        # TODO
        # env {
        #   name = ...
        #   value_source {
        #     secret_key_ref {
        #       secret = google_secret_manager_secret.secret.run_service_account_id
        #       version = 1
        #     }
        #   }
        # }

        resources {
          limits = {
            cpu = "2"
            memory = "8Gi"
          }
        }
      }

      timeout = "1800s"
      max_retries = 3

      service_account = google_service_account.run_sa.email

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

resource "google_cloud_scheduler_job" "job" {
  name     = "${var.project_id}-sch-g-scheduler"
  region   = var.region
  schedule = var.job_schedule
  time_zone = "UTC"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.uploader.name}:run"
    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }
}

resource "google_service_account" "run_sa" {
  account_id   = "gsa-g-uploader"
  display_name = "gsa-g-uploader"
}

resource "google_service_account" "scheduler_sa" {
  account_id   = "gsa-g-scheduler"
  display_name = "gsa-g-scheduler"
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project = google_cloud_run_v2_job.uploader.project
  location = google_cloud_run_v2_job.uploader.location
  name = google_cloud_run_v2_job.uploader.name
  role = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

resource "google_artifact_registry_repository_iam_member" "artifact_registry_reader" {
  location = var.region
  project  = var.project_id
  repository = var.artifact_registry_repository
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.audience_data.name
  role    = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_compute_subnetwork_iam_member" "compute_network_user" {
  subnetwork = google_compute_subnetwork.subnet.name
  role       = "roles/compute.networkUser"
  region     = var.region
  member     = "serviceAccount:${google_service_account.run_sa.email}"
}
