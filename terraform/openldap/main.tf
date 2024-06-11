terraform {
  backend "kubernetes" {
    secret_suffix = "openldap"
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

resource "kubernetes_namespace" "openldap" {
  metadata {
    name = "openldap"
  }
}
