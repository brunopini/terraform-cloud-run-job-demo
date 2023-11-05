variable "google_credentials_path" {
    description = "Path to JSON credentials file"
    type = string
}

variable "env_prefix" {
    type = string
}

variable "project_id" {
    type = string
}

variable "region" {
    type = string
}

variable "region_short" {
    type = string
}

variable "assets_bucket" {
    type = string
}

variable "subnet_cidr" {
    type = string
}

variable "docker_repository_id"{
    type = string
}

variable "image_url" {
    type = string
}

variable "job_schedule" {
    type = string
}

variable "create_github_resources" {
  description = "Whether to create the GitHub service account and pass json key to Github Secrets"
  type        = bool
  default     = false
}

variable "github_repository" {
    type = string
    default ="my-github-repository"
}

variable "github_token" {
    type = string
    default =""
}
