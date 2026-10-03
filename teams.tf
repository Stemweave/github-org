locals {
  teams = yamldecode(file("${path.module}/${var.config_file}")).teams

  # One entry per person per team, keyed "team/username". A list left empty in the file is null in
  # YAML, so treat that the same as [].
  memberships = merge({}, [
    for team, config in local.teams : merge(
      { for user in coalesce(try(config.maintainers, null), []) : "${team}/${user}" => { team = team, username = user, role = "maintainer" } },
      { for user in coalesce(try(config.members, null), []) : "${team}/${user}" => { team = team, username = user, role = "member" } },
    )
    if config != null
  ]...)
}

resource "github_team" "this" {
  for_each = local.teams

  name        = each.key
  description = try(each.value.description, "")
  privacy     = try(each.value.privacy, "closed")
}

resource "github_team_membership" "this" {
  for_each = local.memberships

  team_id  = github_team.this[each.value.team].id
  username = each.value.username
  role     = each.value.role

  # The person must be in the organization first, which members.tf takes care of.
  depends_on = [github_membership.this, terraform_data.guards]
}
