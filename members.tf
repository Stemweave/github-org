locals {
  members = {
    for user, config in coalesce(try(yamldecode(file("${path.module}/${var.members_file}")).members, null), {}) :
    user => merge({ role = "member" }, config)
  }

  # GitHub usernames are not case sensitive, so compare them in lower case.
  member_names = [for user in keys(local.members) : lower(user)]
  admins       = [for user, member in local.members : user if member.role == "admin"]

  team_users_not_in_org = sort(distinct([
    for key, membership in local.memberships : membership.username
    if !contains(local.member_names, lower(membership.username))
  ]))

  unmanaged_members = sort([
    for user in data.github_organization.this.users : lower(user.login)
    if !contains(local.member_names, lower(user.login))
  ])
}

data "github_organization" "this" {
  name = var.owner
}

# Stops a bad members.yaml before anything is applied.
resource "terraform_data" "guards" {
  lifecycle {
    precondition {
      condition     = alltrue([for member in local.members : contains(["member", "admin"], member.role)])
      error_message = "A member's role must be member or admin."
    }

    precondition {
      condition     = length(local.admins) >= 1
      error_message = "At least one person must be an admin, or nobody could manage the organization."
    }

    precondition {
      condition     = length(local.team_users_not_in_org) == 0
      error_message = "These people are in teams.yaml but not in members.yaml: ${join(", ", local.team_users_not_in_org)}. Add them to members.yaml first."
    }
  }
}

resource "github_membership" "this" {
  for_each = local.members

  username = each.key
  role     = each.value.role

  # An admin taken off the list becomes a member and stays in the organization, so one deleted line
  # can't take an owner away. A plain member taken off the list is removed.
  downgrade_on_destroy = each.value.role == "admin"

  depends_on = [terraform_data.guards]
}

# A warning, not a failure: someone invited or added in GitHub's own settings would otherwise stop
# every apply until they were added here.
check "every_member_is_managed" {
  assert {
    condition     = length(local.unmanaged_members) == 0
    error_message = "These people are in the organization but not in members.yaml: ${join(", ", local.unmanaged_members)}. Add them, or remove them from the organization."
  }
}
