terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}

data "terraform_remote_state" "traefik" {
  backend = "kubernetes"

  config = {
    secret_suffix = "traefik"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

data "terraform_remote_state" "keycloak_config" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}
