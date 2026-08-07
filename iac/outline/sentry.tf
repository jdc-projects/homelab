# Sentry error reporting. The org-scoped auth token is minted by iac/sentry's
# bootstrap job and read here via remote_state; this module creates its own
# project and injects the DSN.
data "terraform_remote_state" "sentry" {
  backend = "kubernetes"

  config = {
    secret_suffix = "sentry"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

provider "sentry" {
  token    = data.terraform_remote_state.sentry.outputs.sentry_auth_token
  base_url = "https://sentry.${var.server_base_domain}/api/"
}

resource "sentry_team" "outline" {
  organization = "sentry"
  name         = "Outline"
  slug         = "outline"
}

resource "sentry_project" "outline" {
  organization = "sentry"
  teams        = [sentry_team.outline.slug]
  name         = "Outline"
  slug         = "outline"
  platform     = "node"
}

data "sentry_key" "outline" {
  organization = sentry_project.outline.organization
  project      = sentry_project.outline.id
  first        = true
}

locals {
  sentry_dsn = data.sentry_key.outline.dsn["public"]
}
