variable "google_credentials_file_path" {
    type = string
}

variable "project_id" {
    type = string
}

variable "region" {
    type = string
  default     = "us-central1"
}

variable "region_short" {
    type = string
    default = "uscen1"
}
