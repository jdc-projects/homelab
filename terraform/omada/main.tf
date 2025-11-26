terraform {
  backend "kubernetes" {
    secret_suffix = "omada"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.5.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

resource "kubernetes_namespace" "omada" {
  metadata {
    name = "omada"
  }
}
