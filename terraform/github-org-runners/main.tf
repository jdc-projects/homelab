terraform {
  backend "kubernetes" {
    secret_suffix = "github-org-runners"
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

resource "kubernetes_namespace" "github_org_runners" {
  metadata {
    name = "github-org-runners"

    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
  }
}

locals {
  arc_version    = "0.9.3"
  runner_version = "2.320.0"
}
