terraform {
  backend "kubernetes" {
    secret_suffix = "forward-auth-test"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

resource "kubernetes_namespace" "forward_auth_test" {
  metadata {
    name = "forward-auth-test"
  }
}
