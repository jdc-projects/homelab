terraform {
  backend "kubernetes" {
    secret_suffix = "traefik"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
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

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.40.0"
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

provider "cloudflare" {
  api_token = var.cloudflare_list_ips_token
}

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}
