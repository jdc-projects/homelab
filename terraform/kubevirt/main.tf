terraform {
  backend "kubernetes" {
    secret_suffix = "kubevirt"
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

    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
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

locals {
  kubevirt_version = "v1.4.0"
  cdi_version      = "v1.61.0"
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
