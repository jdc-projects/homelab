terraform {
  backend "kubernetes" {
    secret_suffix = "apps-openldap"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "0.11.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

provider "truenas" {
  api_key  = var.truenas_api_key
  base_url = "https://nas.${var.server_base_domain}/api/v2.0"
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "null" {
  # Configuration options
}

provider "random" {
}

provider "local" {
  # Configuration options
}

resource "kubernetes_namespace" "openldap" {
  metadata {
    name = "openldap"
  }
}
