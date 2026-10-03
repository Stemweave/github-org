# github-org

Terraform for the organization's settings, Actions policy, and teams. Setup and the first run are
in the [overview](../README.md). Apply this one **before** `github-repositories`.

| file | what it is |
|---|---|
| `settings.tf` | base permission, and who may create or fork repositories |
| `actions.tf` | which actions may run, and the default workflow token |
| `members.tf`, `members.yaml` | everyone in the organization, and whether they are a member or an admin |
| `teams.tf`, `teams.yaml` | the teams and who is in them |
| `versions.tf` | the HCP Terraform backend and the provider version |

## What it sets

- **Members** can read every repository and change none until a team grants more. They can't
  create or fork repositories.
- **Actions** may use the ones GitHub publishes, `Stemweave/*`, and `hashicorp/setup-terraform` (the
  Terraform pipeline needs it), and nothing else. A workflow that calls any other action won't start.
  Add to `allowed_action_patterns` to allow more.
- **The default workflow token** is read-only and can't approve pull requests. A workflow that
  needs more asks in its own `permissions:` block, where review can see it.

## Members

`members.yaml` lists everyone in the organization:

```yaml
members:
  WasathTheekshana:
    role: admin
  some-colleague:
    role: member
```

- **Add someone:** add their GitHub username and open a PR. When it merges, GitHub invites them, and
  they are in once they accept. The default role is `member`.
- **Remove someone:** take them off the list. The plan shows their membership being destroyed,
  and merging removes them from the organization.
- **`admin` is an organization owner**, with full control, so keep that to the few people who need it.
- **Removing an admin is two steps.** Taking an admin off the list only turns them into a member, so
  one deleted line can't take an owner away. To remove one fully, change them to `member`, merge,
  then take them off the list.
- **Teams use this list.** A team can only hold people who are in `members.yaml`, and the plan fails
  with the names if one isn't.
- **At least one admin** has to stay on the list.

Terraform can only manage people it knows about. Each plan compares the list with who is really in the
organization and **warns** about anyone who is there but not listed, for example someone invited from
GitHub's own settings. The warning doesn't block anything: add them to the file, or remove them.

Not covered: outside collaborators, and invitations that haven't been accepted yet.

## Teams

```yaml
teams:
  platform:
    description: Owns the shared workflows and the GitHub setup
    maintainers:
      - WasathTheekshana
    members: []
```

The team name becomes its slug, which `github-repositories` uses to give it access.

## How changes are applied

`.github/workflows/terraform.yml` plans on every pull request, applies on a merge to `main`, and can
be run by hand with plan, apply or destroy. See [how runs work](../README.md#how-runs-work).

## Develop

```sh
terraform init -backend=false
terraform test
```

The tests use a mocked provider, so they need no credentials and change nothing.
