locals {
  github_terraform_secret_name = upper(replace("${var.project_id}-gas-g-terraform", "-", "_"))
}
