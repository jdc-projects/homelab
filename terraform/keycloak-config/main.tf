terraform {
  backend "kubernetes" {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

data "terraform_remote_state" "openldap" {
  backend = "kubernetes"

  config = {
    secret_suffix = "openldap"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

data "terraform_remote_state" "prometheus_operator" {
  backend = "kubernetes"

  config = {
    secret_suffix = "prometheus-operator"
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
