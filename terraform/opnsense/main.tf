terraform {
  backend "kubernetes" {
    secret_suffix = "opnsense"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "kubectl" {
  config_path = "../cluster.yml"
}

resource "kubernetes_namespace" "opnsense" {
  metadata {
    name = "opnsense"

    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
  }
}
