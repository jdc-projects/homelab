terraform {
  backend "kubernetes" {
    secret_suffix = "csi-driver-nfs"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
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

resource "kubernetes_namespace" "democratic_csi" {
  metadata {
    name = "democratic-csi"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}