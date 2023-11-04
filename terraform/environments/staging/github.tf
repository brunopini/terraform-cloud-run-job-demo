module "github" {
    source = "../../modules/github"

    create_github_resources=var.create_github_resources
    google_credentials_path=var.google_credentials_path
    project_id = var.project_id
    region = var.region
    github_repository = var.github_repository
}
