terraform {
  required_version = "~> 1.9"

  # State lives in HCP Terraform (formerly Terraform Cloud). Change the organization to yours.
  cloud {
    organization = "Stemweave"

    workspaces {
      name = "github-org"
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}
