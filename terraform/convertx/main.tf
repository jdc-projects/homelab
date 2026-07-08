# ConvertX has no native OIDC / OAuth, and no reverse-proxy header auth (it only
# reads its own JWT cookie). Upstream SSO is tracked in
# https://github.com/C4illin/ConvertX/issues/146 (a collaborator has signalled
# intent to implement it, but no PR has landed yet). A working OIDC
# implementation also exists in the community fork
# https://github.com/NidPlays/Convertx-cc (via PocketID), useful as a reference
# should we ever move off the base image.
#
# Until native SSO lands we run the base image in anonymous mode
# (ALLOW_UNAUTHENTICATED=true) with history disabled, and rely on the
# traefik-oidc-auth Keycloak middleware to gate access. This is only safe because
# ConvertX is reachable solely through that OIDC-protected ingress - the service
# is an internal ClusterIP, so nothing else can reach the unauthenticated app.

terraform {
  backend "kubernetes" {
    secret_suffix = "convertx"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

resource "kubernetes_namespace" "convertx" {
  metadata {
    name = "convertx"
  }
}
