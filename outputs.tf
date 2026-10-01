output "teams" {
  description = "Each team's slug, which the repositories list uses to give it access."
  value       = { for name, team in github_team.this : name => team.slug }
}

output "memberships" {
  description = "Each person's role in each team, keyed \"team/username\"."
  value       = { for key, membership in local.memberships : key => membership.role }
}
