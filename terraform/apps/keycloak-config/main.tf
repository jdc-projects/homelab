terraform {
  backend "kubernetes" {
    secret_suffix = "apps-keycloak-config"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.2.0"
    }
  }
}

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "apps-keycloak"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = "https://idp.${var.server_base_domain}"
}
