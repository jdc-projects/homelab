terraform {
  backend "kubernetes" {
    secret_suffix = "apps-needs-storage"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "0.11.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

provider "truenas" {
  api_key  = var.truenas_api_key
  base_url = "nas.${var.server_base_url}"
}

provider "kubernetes" {
  config_path = "../../cluster.yml"
}

provider "helm" {
  kubernetes {
    config_path = "../../cluster.yml"
  }
}
