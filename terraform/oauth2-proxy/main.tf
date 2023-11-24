terraform {
  backend "kubernetes" {
    secret_suffix = "oauth2-proxy"
    config_path   = "../cluster.yml"
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

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.3.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
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

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak_config.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak_config.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url
}

provider "random" {
}

data "terraform_remote_state" "keycloak_config" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }
}

resource "kubernetes_namespace" "oauth2_proxy" {
  metadata {
    name = "oauth2-proxy"
  }
}
