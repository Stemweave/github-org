locals {
  teams = yamldecode(file("${path.module}/${var.config_file}")).teams

  # One entry per person per team, keyed "team/username".
  memberships = merge({}, [
    for team, config in local.teams : merge(
      { for user in try(config.maintainers, []) : "${team}/${user}" => { team = team, username = user, role = "maintainer" } },
      { for user in try(config.members, []) : "${team}/${user}" => { team = team, username = user, role = "member" } },
    )
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
}
