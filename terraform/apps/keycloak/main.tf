terraform {
  backend "kubernetes" {
    secret_suffix = "apps-keycloak"
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

    # keycloak = {
    #   source  = "mrparkers/keycloak"
    #   version = "4.3.1"
    # }
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

# provider "keycloak" {
#   client_id = "admin-cli"
#   username  = random_password.keycloak_admin_username.result
#   password  = random_password.keycloak_admin_password.result
#   url       = "https://idp.${var.server_base_domain}"
# }

resource "kubernetes_namespace" "keycloak_namespace" {
  metadata {
    name = "keycloak"
  }
}
