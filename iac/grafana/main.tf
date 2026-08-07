terraform {
  backend "kubernetes" {
    secret_suffix = "grafana"
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

    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.8"
    }

    sentry = {
      source  = "jianyuan/sentry"
      version = "0.15.4"
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

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"
  }
}
