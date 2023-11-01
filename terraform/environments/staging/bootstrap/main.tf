resource "google_storage_bucket" "terraform_state" {
  name     = "${var.project_id}-gcs-${var.region_short}-assets"
  location = var.region

  versioning {
    enabled = true
  }
}

resource "google_artifact_registry_repository" "repository" {
  location      = var.region
  repository_id = "${var.project_id}-arr-${var.region_short}-docker"
  format        = "DOCKER"
}
