mock_provider "github" {}

variables {
  config_file                = "tests/fixtures/teams.yaml"
  github_app_id              = "1"
  github_app_installation_id = "1"
  github_app_pem_file        = "not a real key"
  billing_email              = "billing@example.com"
}

run "memberships_are_flattened_with_the_right_role" {
  command = plan

  assert {
    condition = jsonencode(output.memberships) == jsonencode({
      "platform/alice" = "maintainer"
      "platform/bob"   = "member"
      "platform/carol" = "member"
      "reviewers/bob"  = "member"
    })
    error_message = "Unexpected memberships: ${jsonencode(output.memberships)}"
  }
}

run "a_team_with_no_people_is_still_created" {
  command = plan

  assert {
    condition     = length(github_team.this) == 3 && github_team.this["empty"].privacy == "closed"
    error_message = "Every team in the file should exist, closed unless it says otherwise"
  }

  assert {
    condition     = github_team.this["reviewers"].privacy == "secret"
    error_message = "A team's privacy should come from the file"
  }
}

run "only_the_listed_third_party_actions_are_allowed" {
  command = plan

  assert {
    condition     = github_actions_organization_permissions.this.allowed_actions == "selected" && github_actions_organization_permissions.this.allowed_actions_config[0].patterns_allowed == toset(["Stemweave/*", "hashicorp/setup-terraform@*"])
    error_message = "Actions should be limited to GitHub's own, Stemweave/*, and setup-terraform"
  }

  assert {
    condition     = github_actions_organization_workflow_permissions.this.default_workflow_permissions == "read"
    error_message = "The default workflow token should be read-only"
  }
}
