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

resource "sentry_team" "grafana" {
  organization = "sentry"
  name         = "Grafana"
  slug         = "grafana"
}

resource "sentry_project" "grafana" {
  organization = "sentry"
  teams        = [sentry_team.grafana.slug]
  name         = "Grafana"
  slug         = "grafana"
  platform     = "javascript-react"
}

data "sentry_key" "grafana" {
  organization = sentry_project.grafana.organization
  project      = sentry_project.grafana.id
  first        = true
}

locals {
  sentry_dsn = data.sentry_key.grafana.dsn["public"]
}
