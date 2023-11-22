terraform {
  backend "kubernetes" {
    secret_suffix = "trivy"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "null" {
  # Configuration options
}

resource "kubernetes_namespace" "trivy" {
  metadata {
    name = "trivy"
  }
}
