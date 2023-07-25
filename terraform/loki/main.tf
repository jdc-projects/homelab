terraform {
  backend "kubernetes" {
    secret_suffix = "loki"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
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

provider "random" {
}

resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"
  }

  # since the pvcs will be deleted if this is, but the promtail hostpath data will remain,
  # make this difficult to destroy as a safety mechanism and to force a sanity check.
  lifecycle {
    prevent_destroy = true
  }
}
