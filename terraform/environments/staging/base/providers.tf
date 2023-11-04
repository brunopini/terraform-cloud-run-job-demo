terraform {
  required_version = "1.6.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.3.0"
    }
  }
}

provider "google" {
  credentials = file(var.google_credentials_path)
  project     = var.project_id
  region      = var.region
}
