terraform {
  backend "kubernetes" {
    secret_suffix = "apps-keycloak"
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

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.2.0"
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

provider "keycloak" {
  client_id = "admin-cli"
  username  = random_password.keycloak_admin_username.result
  password  = random_password.keycloak_admin_password.result
  url       = kubernetes_config_map.keycloak_configmap.data.KC_DB_URL_HOST
}

resource "kubernetes_namespace" "keycloak_namespace" {
  metadata {
    name = "keycloak"
  }
}
