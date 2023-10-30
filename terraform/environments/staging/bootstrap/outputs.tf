output "project_id" {
    value = var.project_id
}

output "assets_bucket" {
    value = google_storage_bucket.terraform_state.name
}

output "registry_base_url" {
  value = "${google_artifact_registry_repository.repository.location}-docker.pkg.dev"
}

output "repository_id" {
  value = "${google_artifact_registry_repository.repository.repository_id}"
}
