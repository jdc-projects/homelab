terraform {
  backend "kubernetes" {
    secret_suffix = "keycloak"
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

# provider is required by the ingress module, but not used, so values don't matter
provider "keycloak" {
  client_id     = "admin-cli"
  username      = ""
  password      = ""
  url           = ""
  initial_login = false
}

locals {
  keycloak_domain = "idp.${var.server_base_domain}"
}

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
  }
}
