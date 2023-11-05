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
