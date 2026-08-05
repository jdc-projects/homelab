terraform {
  backend "kubernetes" {
    secret_suffix = "tempo"
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

# Cross-module read of the Grafana instance selector labels so the Tempo
# GrafanaDatasource CR (in grafana-datasource.tf) targets the right instance,
# mirroring the pattern in iac/prometheus/grafana-datasource.tf.
data "terraform_remote_state" "grafana" {
  backend = "kubernetes"

  config = {
    secret_suffix = "grafana"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

resource "kubernetes_namespace" "tempo" {
  metadata {
    name = "tempo"
  }
}
