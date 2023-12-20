terraform {
  backend "kubernetes" {
    secret_suffix = "vaultwarden"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
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

resource "kubernetes_namespace" "vaultwarden" {
  metadata {
    name = "vaultwarden"
  }
}
