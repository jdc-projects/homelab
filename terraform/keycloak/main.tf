terraform {
  backend "kubernetes" {
    secret_suffix = "keycloak"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../cluster.yml"
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

data "terraform_remote_state" "prometheus_operator" {
  backend = "kubernetes"

  config = {
    secret_suffix = "prometheus-operator"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
  }
}
