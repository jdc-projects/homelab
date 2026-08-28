terraform {
  backend "kubernetes" {
    secret_suffix = "github-org-runners"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "helm" {
  kubernetes = {
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
  arc_version    = "0.14.2"
  runner_version = "2.337.0"
}
