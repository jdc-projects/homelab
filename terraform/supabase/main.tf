terraform {
  backend "kubernetes" {
    secret_suffix = "supabase"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"

    # ***** temporary
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

    jwt = {
      source  = "camptocamp/jwt"
      version = "1.1.0"
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

resource "kubernetes_namespace" "supabase" {
  metadata {
    name = "supabase"

    # ***** temporary
    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
  }
}
