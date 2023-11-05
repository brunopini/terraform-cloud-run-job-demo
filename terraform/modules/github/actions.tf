# Google Cloud resources =================================================
resource "google_service_account" "github" {
  count = var.create_github_resources ? 1 : 0

  account_id   = "gsa-g-github"
  display_name = "gsa-g-github"
}

resource "google_project_iam_member" "github" {
  count = var.create_github_resources ? 1 : 0

  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.github[0].email}"
}

resource "google_service_account_key" "github" {
  count = var.create_github_resources ? 1 : 0

  service_account_id = google_service_account.github[0].name
  private_key_type    = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# Github Secrets =========================================================
resource "github_actions_secret" "terraform" {
  count = var.create_github_resources ? 1 : 0

  repository       = var.github_repository
  secret_name      = local.github_terraform_secret_name
  plaintext_value  = base64decode(google_service_account_key.github[0].private_key)

  depends_on =[google_service_account_key.github[0]]
}

resource "github_actions_secret" "github_token" {
  count = var.create_github_resources ? 1 : 0

  repository       = var.github_repository
  secret_name      = "GIT_PAT_TOKEN"
  plaintext_value  = var.git_pat_token
}

resource "github_actions_secret" "assets_bucket" {
  count = var.create_github_resources ? 1 : 0

  repository       = var.github_repository
  secret_name      = "ASSETS_BUCKET"
  plaintext_value  = var.assets_bucket
}

resource "github_actions_secret" "terraform_name" {
  count = var.create_github_resources ? 1 : 0

  repository       = var.github_repository
  secret_name      = "TERRAFORM_SECRET_NAME"
  plaintext_value  = local.github_terraform_secret_name
}
