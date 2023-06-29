terraform {
  backend "kubernetes" {
    secret_suffix = "apps-keycloak-config"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.3.1"
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

data "terraform_remote_state" "lldap" {
  backend = "kubernetes"

  config = {
    secret_suffix = "apps-lldap"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak.outputs.keycloak_hostname_url
}
