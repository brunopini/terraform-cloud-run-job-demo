output "project_id" {
    value = var.project_id
}

output "assets_bucket" {
    value = var.assets_bucket
}

output "registry_base_url" {
  value = "${google_artifact_registry_repository.docker.location}-docker.pkg.dev"
}

output "docker_repository_id" {
  value = "${google_artifact_registry_repository.docker.repository_id}"
}

output "registry_id" {
  value = "${google_artifact_registry_repository.docker.id}"
}
output "image_url" {
    value = var.image_url
}

output "create_github_resources" {
  value = var.create_github_resources
}

output "github_repository" {
  value = var.github_repository
}
