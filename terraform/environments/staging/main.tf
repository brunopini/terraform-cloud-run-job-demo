resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-sbn-${var.region_short}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.name

  depends_on = [google_compute_network.vpc]
}

resource "google_compute_firewall" "firewall_egress" {
  name    = "${var.project_id}-fwe-${var.region_short}-vpcegress"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  destination_ranges = ["0.0.0.0/0"]

  direction = "EGRESS"

  depends_on = [google_compute_network.vpc]
}

resource "google_compute_router" "router" {
  name    = "${var.project_id}-rtr-g-vpcrouter"
  region  = var.region
  network = google_compute_network.vpc.name

  depends_on = [google_compute_network.vpc]
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

  depends_on = [google_compute_router.router, google_compute_subnetwork.subnet]
}

# TODO
# resource "google_storage_bucket" "bucket" {
#   name     = "${var.project_id}-gcs-${var.region_short}-bucket"
#   location = var.region
# }

resource "google_cloud_run_v2_job" "job" {
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

  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
}

resource "google_cloud_scheduler_job" "scheduler" {
  name     = "${var.project_id}-sch-g-scheduler"
  region   = var.region
  schedule = var.job_schedule
  time_zone = "UTC"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.job.name}:run"
    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }
}

resource "google_service_account" "job_sa" {
  account_id   = "gsa-g-job"
  display_name = "gsa-g-job"
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

resource "google_artifact_registry_repository_iam_member" "artifact_registry_reader" {
  location = var.region
  project  = var.project_id
  repository = var.artifact_registry_repository
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.job_sa.email}"
}

# TODO
# resource "google_storage_bucket_iam_member" "bucket_admin" {
#   bucket = google_storage_bucket.bucket.name
#   role    = "roles/storage.admin"
#   member = "serviceAccount:${google_service_account.job_sa.email}"
# }

resource "google_compute_subnetwork_iam_member" "compute_network_user" {
  subnetwork = google_compute_subnetwork.subnet.name
  role       = "roles/compute.networkUser"
  region     = var.region
  member     = "serviceAccount:${google_service_account.job_sa.email}"

  depends_on = [google_compute_subnetwork.subnet]
}
