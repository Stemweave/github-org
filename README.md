# github-org

Terraform for the organization's settings, Actions policy, and teams. Setup and the first run are
in the [overview](../README.md). Apply this one **before** `github-repositories`.

| file | what it is |
|---|---|
| `settings.tf` | base permission, and who may create or fork repositories |
| `actions.tf` | which actions may run, and the default workflow token |
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
