terraform {
  backend "kubernetes" {
    secret_suffix = "loki"
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

    grafana = {
      source  = "grafana/grafana"
      version = "3.1.0"
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

data "terraform_remote_state" "grafana" {
  backend = "kubernetes"

  config = {
    secret_suffix = "grafana"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"
  }
}
