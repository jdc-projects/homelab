terraform {
  backend "kubernetes" {
    secret_suffix = "traefik"
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

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
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

provider "null" {
  # Configuration options
}
