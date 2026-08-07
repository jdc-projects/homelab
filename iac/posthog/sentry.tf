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

resource "sentry_team" "posthog" {
  organization = "sentry"
  name         = "PostHog"
  slug         = "posthog"
}

resource "sentry_project" "posthog" {
  organization = "sentry"
  teams        = [sentry_team.posthog.slug]
  name         = "PostHog"
  slug         = "posthog"
  platform     = "python-django"
}

data "sentry_key" "posthog" {
  organization = sentry_project.posthog.organization
  project      = sentry_project.posthog.id
  first        = true
}

locals {
  sentry_dsn = data.sentry_key.posthog.dsn["public"]
}
