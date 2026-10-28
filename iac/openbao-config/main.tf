terraform {
  backend "kubernetes" {
    secret_suffix = "openbao-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.8"
    }

    # OpenBao is API-compatible with Vault for everything managed here (JWT
    # auth, Kubernetes auth, policies, KV mount, audit). TODO: switch to the
    # dedicated `openbao` provider once it ships (see README.md).
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

# Token from the one-time bootstrap (`openbao-bootstrap` secret in the openbao
# namespace; set as the OPENBAO_ROOT_TOKEN GitHub secret). TODO: replace with
# Kubernetes-auth and revoke root — see README.md.
provider "vault" {
  address = "https://${local.openbao_domain}"
  token   = var.openbao_root_token
}

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

locals {
  openbao_domain = "bao.${var.server_base_domain}"

  # Redirect URIs registered both here (Keycloak) and on the OpenBao role —
  # they must match exactly. UI keeps Vault's /ui/vault/ path for
  # compatibility; localhost is the CLI (`bao login -method=oidc`) listener.
  oidc_redirect_uris = [
    "https://${local.openbao_domain}/ui/vault/auth/oidc/oidc/callback",
    "https://${local.openbao_domain}/v1/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
}
