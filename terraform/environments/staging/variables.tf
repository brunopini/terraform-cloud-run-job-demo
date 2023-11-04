variable "google_credentials_path" {
    type = string
    description = "Path to JSON credentials file"
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
