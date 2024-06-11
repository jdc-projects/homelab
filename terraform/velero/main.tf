terraform {
  backend "kubernetes" {
    secret_suffix = "velero"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"

    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
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

resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"

    labels = {
      "velero.io/exclude-from-backup"      = "true"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}
