terraform {
  required_version = "1.6.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.3.0"
    }

    github = {
      source  = "integrations/github"
      version = "5.41"
    }
  }
}

# provider "google" {
#   credentials = var.google_credentials_path
#   project     = var.project_id
#   region      = var.region
# }

# provider "github" {
#   # implicitly passed via env variable GITHUB_TOKEN
# }
