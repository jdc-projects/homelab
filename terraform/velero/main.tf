terraform {
  backend "kubernetes" {
    secret_suffix = "velero"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
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

provider "null" {
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
