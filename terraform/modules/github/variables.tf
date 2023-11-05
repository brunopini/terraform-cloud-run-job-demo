variable "google_credentials_path" {
    description = "Path to JSON credentials file"
    type = string
}

variable "project_id" {
    type = string
}

variable "region" {
    type = string
}

variable "assets_bucket" {
    type = string
}

variable "create_github_resources" {
  description = "Whether to create the GitHub service account and pass json key to Github Secrets"
  type        = bool
  default     = true
}

variable "github_repository" {
    description = "Github repository ID to pass secrets into"
}
