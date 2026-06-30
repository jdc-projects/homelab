terraform {
  backend "kubernetes" {
    secret_suffix = "kubevirt"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.0"
    }

    ssh = {
      source  = "loafoe/ssh"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

# provider is required by the ingress module, but not used, so values don't matter
provider "keycloak" {
  client_id     = "admin-cli"
  username      = ""
  password      = ""
  url           = ""
  initial_login = false
}

data "kubernetes_namespace" "kubevirt" {
  metadata {
    name = "kubevirt"
  }
}

data "kubernetes_namespace" "cdi" {
  metadata {
    name = "cdi"
  }
}
