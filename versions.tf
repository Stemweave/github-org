terraform {
  required_version = "~> 1.9"

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
