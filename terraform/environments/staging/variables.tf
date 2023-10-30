variable "google_credentials_file_path" {
    type = string
}

variable "env_prefix" {
    type = string
    default = "s"
}

variable "project_id" {
    type = string
}

variable "region" {
    type = string
    default = "us-central1"
}

variable "region_short" {
    type = string
    default = "uscen1"
}

variable "subnet_cidr" {
    type = string
    default = "10.0.15.0/24"
}

variable "artifact_registry_repository"{
    type = string
}

variable "image_uri" {
    type = string
}

variable "job_schedule" {
    type = string
    default = "0 0 * * *"
}
