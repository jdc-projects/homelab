terraform {
  backend "kubernetes" {
    secret_suffix = "foundation-part1"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
    insecure      = true
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.1"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../../cluster.yml"
    insecure    = true
  }
}

provider "kubernetes" {
  config_path = "../../cluster.yml"
  insecure    = true
}
