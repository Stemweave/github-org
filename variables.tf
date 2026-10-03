variable "owner" {
  description = "The GitHub organization to manage."
  type        = string
  default     = "Stemweave"
}

variable "github_app_id" {
  description = "The ID of the GitHub App Terraform signs in as. Set it as a variable on the HCP Terraform workspace."
  type        = string
}

variable "github_app_installation_id" {
  description = "The ID of that App's installation in the organization. Set it on the workspace."
  type        = string
}

variable "github_app_pem_file" {
  description = "The App's private key, the whole .pem file. Set it on the workspace and mark it sensitive."
  type        = string
  sensitive   = true
}

variable "billing_email" {
  description = "The organization's billing email. GitHub requires one when settings are managed. Set it on the workspace."
  type        = string
}

variable "allowed_action_patterns" {
  description = "Actions the organization's workflows may use, besides the ones GitHub publishes. Stemweave/* is the shared workflows. hashicorp/setup-terraform is what the Terraform pipeline uses, so removing it stops these repositories' own pipelines."
  type        = list(string)
  default     = ["Stemweave/*", "hashicorp/setup-terraform@*"]
}

variable "config_file" {
  description = "The file listing the teams, relative to this folder."
  type        = string
  default     = "teams.yaml"
}

variable "members_file" {
  description = "The file listing everyone in the organization, relative to this folder."
  type        = string
  default     = "members.yaml"
}
