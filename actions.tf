# Workflows may use actions GitHub publishes and the ones listed in allowed_action_patterns, and
# nothing else. A workflow that calls an action from anywhere else fails to start.
resource "github_actions_organization_permissions" "this" {
  allowed_actions      = "selected"
  enabled_repositories = "all"

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = false
    patterns_allowed     = var.allowed_action_patterns
  }
}

# A workflow's token starts read-only, and can't approve pull requests. A workflow that needs more
# asks for it with a `permissions:` block, which is visible in review.
resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug                = var.owner
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}
