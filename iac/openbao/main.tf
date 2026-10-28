terraform {
  backend "kubernetes" {
    secret_suffix = "openbao"
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

    # Not used directly in this module, but the shared ingress module declares
    # it (its OIDC auth resources are count-gated on auth_mode, which is "none"
    # here) — configured for parity with the other app modules.
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

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

resource "kubernetes_namespace" "openbao" {
  metadata {
    name = "openbao"
  }
}

locals {
  openbao_domain = "bao.${var.server_base_domain}"
}
