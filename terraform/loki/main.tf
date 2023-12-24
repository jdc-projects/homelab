terraform {
  backend "kubernetes" {
    secret_suffix = "loki"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "2.8.0"
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

provider "grafana" {
  url  = data.terraform_remote_state.prometheus_operator.outputs.grafana_url
  auth = "${data.terraform_remote_state.prometheus_operator.outputs.grafana_admin_username}:${data.terraform_remote_state.prometheus_operator.outputs.grafana_admin_password}"
}

resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"
  }
}
