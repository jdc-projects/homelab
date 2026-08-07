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

resource "sentry_team" "erpnext" {
  organization = "sentry"
  name         = "ERPNext"
  slug         = "erpnext"
}

resource "sentry_project" "erpnext" {
  organization = "sentry"
  teams        = [sentry_team.erpnext.slug]
  name         = "ERPNext"
  slug         = "erpnext"
  platform     = "python"
}

data "sentry_key" "erpnext" {
  organization = sentry_project.erpnext.organization
  project      = sentry_project.erpnext.id
  first        = true
}

locals {
  sentry_dsn = data.sentry_key.erpnext.dsn["public"]
}
