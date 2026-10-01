resource "github_organization_settings" "this" {
  billing_email = var.billing_email

  # Members can read every repository but change none until a team grants more. Creating and
  # forking repositories is for owners, so new repositories are made through github-repositories.
  default_repository_permission         = "read"
  members_can_create_repositories       = false
  members_can_fork_private_repositories = false
}
