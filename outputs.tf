output "teams" {
  description = "Each team's slug, which the repositories list uses to give it access."
  value       = { for name, team in github_team.this : name => team.slug }
}

output "memberships" {
  description = "Each person's role in each team, keyed \"team/username\"."
  value       = { for key, membership in local.memberships : key => membership.role }
}

output "members" {
  description = "Everyone Terraform manages in the organization, with their role."
  value       = { for user, member in local.members : user => member.role }
}

output "unmanaged_members" {
  description = "People who are in the organization but not in members.yaml."
  value       = local.unmanaged_members
}
