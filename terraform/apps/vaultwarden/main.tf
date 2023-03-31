terraform {
  backend "kubernetes" {
    secret_suffix = "apps-vaultwarden"
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
  }
}

provider "truenas" {
  api_key  = var.truenas_api_key
  base_url = "https://nas.${var.server_base_domain}/api/v2.0"
}

provider "kubernetes" {
  config_path = "../../cluster.yml"
}

resource "kubernetes_namespace" "vaultwarden_namespace" {
  metadata {
    name = "vaultwarden"
  }
}
