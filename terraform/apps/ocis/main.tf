terraform {
  backend "kubernetes" {
    secret_suffix = "apps-nextcloud"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "0.11.1"
    }

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

provider "truenas" {
  api_key  = var.truenas_api_key
  base_url = "https://nas.${var.server_base_domain}/api/v2.0"
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

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "apps-keycloak"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }
}

resource "kubernetes_namespace" "ocis_namespace" {
  metadata {
    name = "ocis"
  }
}
