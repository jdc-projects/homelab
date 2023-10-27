terraform {
  backend "kubernetes" {
    secret_suffix = "harbor-config"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.3.1"
    }

    harbor = {
      source  = "goharbor/harbor"
      version = "3.10.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }

    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
  }
}

data "terraform_remote_state" "keycloak_config" {
  backend = "kubernetes"

  config = {
    secret_suffix = "apps-keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }
}

data "terraform_remote_state" "harbor" {
  backend = "kubernetes"

  config = {
    secret_suffix = "harbor"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak_config.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak_config.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url
}

provider "harbor" {
  url      = "https://harbor.${var.server_base_domain}"
  username = data.terraform_remote_state.harbor.outputs.harbor_admin_username
  password = data.terraform_remote_state.harbor.outputs.harbor_admin_password
}

provider "random" {
}

provider "ssh" {
}