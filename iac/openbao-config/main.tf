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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    # OpenBao is API-compatible with Vault for everything managed here (JWT
    # auth, Kubernetes auth, policies, KV mount). TODO: switch to the
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

provider "kubernetes" {
  config_path = "../cluster.yml"
}

# The provider exchanges a short-lived ServiceAccount JWT for a Vault token
# via Kubernetes auth (role openbao-config in ci-auth.tf). The JWT is minted
# per-run by the deploy workflow (fetch-openbao-token input).
#
# Bootstrap / recovery (role missing or broken): temporarily replace the
# auth_login_jwt block with `token = <root-or-SSO-admin-token>` and apply
# once — see README.md.
provider "vault" {
  address = "https://${local.openbao_domain}"

  auth_login_jwt {
    mount = "kubernetes"
    role  = "openbao-config"
    jwt   = var.openbao_k8s_jwt
  }
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
