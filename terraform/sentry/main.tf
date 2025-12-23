terraform {
  backend "kubernetes" {
    secret_suffix = "sentry"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.5.0"
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
  client_id     = "admin-cli"
  username      = ""
  password      = ""
  url           = ""
  initial_login = false
}

resource "kubernetes_namespace" "sentry" {
  metadata {
    name = "sentry"
  }
}
