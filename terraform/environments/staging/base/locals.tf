locals {
    registry_id = "projects/${var.project_id}/locations/${var.region}/repositories/${google_artifact_registry_repository.docker.repository_id}"
}