terraform {
  backend "kubernetes" {
    secret_suffix = "traefik-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "cloudflare" {
  api_token = var.cloudflare_list_ips_token
}

data "terraform_remote_state" "traefik" {
  backend = "kubernetes"

  config = {
    secret_suffix = "traefik"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

data "terraform_remote_state" "crowdsec" {
  backend = "kubernetes"

  config = {
    secret_suffix = "crowdsec"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}
