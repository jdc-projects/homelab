terraform {
  backend "kubernetes" {
    secret_suffix = "github-org-runners-1"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../../cluster.yml"
  }
}

provider "kubernetes" {
  config_path = "../../cluster.yml"
}

resource "kubernetes_namespace" "github_org_runners" {
  metadata {
    name = "github-org-runners"
  }
}
