module "github" {
    source = "../../modules/github"

    providers = {
        google = google.provider
    }

    create_github_resources=var.create_github_resources
    google_credentials_path=var.google_credentials_path
    project_id = var.project_id
    region = var.region
    github_repository = var.github_repository

    assets_bucket = var.assets_bucket
}
