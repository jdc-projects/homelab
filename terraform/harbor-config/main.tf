terraform {
  backend "kubernetes" {
    secret_suffix = "harbor-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }

    harbor = {
      source  = "goharbor/harbor"
      version = "3.10.11"
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

data "terraform_remote_state" "harbor" {
  backend = "kubernetes"

  config = {
    secret_suffix = "harbor"
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

provider "harbor" {
  url      = "https://harbor.${var.server_base_domain}"
  username = data.terraform_remote_state.harbor.outputs.harbor_admin_username
  password = data.terraform_remote_state.harbor.outputs.harbor_admin_password
}
