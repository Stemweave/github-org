mock_provider "github" {
  mock_data "github_organization" {
    defaults = {
      users = [{ login = "alice" }, { login = "bob" }, { login = "carol" }]
    }
  }
}

variables {
  config_file                = "tests/fixtures/teams.yaml"
  members_file               = "tests/fixtures/members.yaml"
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
    condition     = length(github_team.this) == 4 && github_team.this["empty"].privacy == "closed"
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

run "everyone_in_the_file_gets_a_membership_with_their_role" {
  command = plan

  assert {
    condition     = jsonencode(output.members) == jsonencode({ "Bob" = "member", "alice" = "admin", "carol" = "member" })
    error_message = "Unexpected members: ${jsonencode(output.members)}"
  }

  assert {
    condition     = github_membership.this["alice"].role == "admin" && github_membership.this["Bob"].role == "member"
    error_message = "Each membership should carry the role from the file"
  }

  assert {
    condition     = length(output.unmanaged_members) == 0
    error_message = "Nobody is in the organization without being in the file here, got ${jsonencode(output.unmanaged_members)}"
  }
}

run "an_admin_taken_off_the_list_is_downgraded_and_a_member_is_removed" {
  command = plan

  assert {
    condition     = github_membership.this["alice"].downgrade_on_destroy == true
    error_message = "An admin should be downgraded, not removed, when taken off the list"
  }

  assert {
    condition     = github_membership.this["Bob"].downgrade_on_destroy == false && github_membership.this["carol"].downgrade_on_destroy == false
    error_message = "A plain member taken off the list should leave the organization"
  }
}

run "someone_in_the_organization_but_not_the_file_is_reported" {
  command = plan

  override_data {
    target = data.github_organization.this
    values = {
      users = [{ login = "alice" }, { login = "bob" }, { login = "carol" }, { login = "Stranger" }]
    }
  }

  expect_failures = [check.every_member_is_managed]
}

run "names_are_compared_without_regard_to_case" {
  command = plan

  override_data {
    target = data.github_organization.this
    values = {
      users = [{ login = "ALICE" }, { login = "bob" }, { login = "CAROL" }]
    }
  }

  assert {
    condition     = length(output.unmanaged_members) == 0
    error_message = "ALICE and alice are the same person, got ${jsonencode(output.unmanaged_members)}"
  }
}

run "an_organization_needs_an_admin" {
  command = plan

  variables {
    members_file = "tests/fixtures/members_no_admin.yaml"
  }

  expect_failures = [terraform_data.guards]
}

run "a_role_must_be_member_or_admin" {
  command = plan

  variables {
    members_file = "tests/fixtures/members_bad_role.yaml"
  }

  expect_failures = [terraform_data.guards]
}

run "a_team_can_only_hold_people_who_are_listed_as_members" {
  command = plan

  variables {
    config_file = "tests/fixtures/teams_with_a_stranger.yaml"
  }

  expect_failures = [terraform_data.guards]
}
