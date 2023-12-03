terraform {
  backend "kubernetes" {
    secret_suffix = "ocis"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"

    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.3.1"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../cluster.yml"
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "null" {
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak_config.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak_config.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url
}

provider "random" {
}

data "terraform_remote_state" "keycloak_config" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }
}

data "terraform_remote_state" "openldap" {
  backend = "kubernetes"

  config = {
    secret_suffix = "openldap"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }
}

resource "kubernetes_namespace" "ocis" {
  metadata {
    name = "ocis"

    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
  }
}
