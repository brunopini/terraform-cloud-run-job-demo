locals {
  github_terraform_secret_name = replace("${var.project_id}-gas-g-terraform", "-", "_")
}
