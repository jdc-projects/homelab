terraform {
  backend "kubernetes" {
    secret_suffix = "knative"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    # Required by the shared ingress module (used by the Tier-2 test fn); only
    # actually invoked when auth_mode is an oidc mode. Mirrors iac/13ft.
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.8"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = "../cluster.yml"
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

locals {
  # Pinned to the latest minor the Knative Operator (v1.22.3) ships. The
  # operator resolves this to the latest matching patch. Knative components are
  # kept on the same minor.
  knative_version = "1.22"

  # The Traefik Knative provider's ingress class (Knative convention:
  # <name>.ingress.networking.knative.dev). Must match the provider enabled in
  # iac/traefik.
  ingress_class = "traefik.ingress.networking.knative.dev"
}

resource "kubernetes_namespace" "knative_serving" {
  metadata {
    name = "knative-serving"
  }
}

resource "kubernetes_namespace" "knative_eventing" {
  metadata {
    name = "knative-eventing"
  }
}
