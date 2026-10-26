terraform {
  backend "kubernetes" {
    secret_suffix = "coder-template"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    coderd = {
      source  = "coder/coderd"
      version = "~> 0.0.30"
    }
  }
}

# API token auto-minted by the iac/coder bootstrap job (see
# ../coder/bootstrap.tf) — sentry-style: minted from inside the deployment,
# exported via state output, no GitHub secrets or manual logins.
data "terraform_remote_state" "coder" {
  backend = "kubernetes"

  config = {
    secret_suffix = "coder"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

# Why this is a separate module from iac/coder: the coderd provider talks to
# the live coderd API — including at plan time, when state refresh reads the
# template back over HTTP. iac/coder must stay plannable while coderd is down
# (first bootstrap, DB hibernation), so template management cannot live there.
# deploy.yml orders this module after iac/coder (deploy-bulk) has converged,
# which also guarantees the token output exists by the time we read it.
provider "coderd" {
  # Same URL as the dashboard — the sentry-consumer pattern (iac/outline,
  # iac/grafana): reachable from both the in-cluster runners and a laptop.
  url   = "https://coder.${var.server_base_domain}"
  token = data.terraform_remote_state.coder.outputs.coder_api_token
}
