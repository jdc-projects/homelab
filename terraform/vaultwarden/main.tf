terraform {
  backend "kubernetes" {
    secret_suffix = "vaultwarden"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

data "terraform_remote_state" "openldap" {
  backend = "kubernetes"

  config = {
    secret_suffix = "openldap"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

# provider is required by the ingress module, but not used, so values don't matter
provider "keycloak" {
  client_id     = "admin-cli"
  username      = ""
  password      = ""
  url           = ""
  initial_login = false
}

resource "kubernetes_namespace" "vaultwarden" {
  metadata {
    name = "vaultwarden"
  }
}
