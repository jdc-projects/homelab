terraform {
  backend "kubernetes" {
    secret_suffix = "openldap"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "null" {
}

provider "random" {
}

provider "local" {
}

resource "kubernetes_namespace" "openldap" {
  metadata {
    name = "openldap"
  }
}
