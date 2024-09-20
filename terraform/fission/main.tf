terraform {
  backend "kubernetes" {
    secret_suffix = "fission"
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

resource "kubernetes_namespace" "fission" {
  for_each = toset([
    "core",
    "builder",
    "functions",
    "environments",
    "apps",
  ])
  metadata {
    name = "fission-${each.value}"
  }
}
