terraform {
  backend "kubernetes" {
    secret_suffix = "drawio"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

resource "kubernetes_namespace" "drawio" {
  metadata {
    name = "drawio"
  }
}
