terraform {
  backend "kubernetes" {
    secret_suffix = "apps-vaultwarden"
    config_path   = "../../cluster.yml"
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

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
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

provider "random" {
}

data "terraform_remote_state" "openldap" {
  backend = "kubernetes"

  config = {
    secret_suffix = "apps-openldap"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }
}

resource "kubernetes_namespace" "vaultwarden_namespace" {
  metadata {
    name = "vaultwarden"
  }
}
