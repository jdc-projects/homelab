terraform {
  backend "kubernetes" {
    secret_suffix = "apps-openldap"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "null" {
  # Configuration options
}

provider "random" {
}

provider "local" {
  # Configuration options
}

resource "kubernetes_namespace" "openldap" {
  metadata {
    name = "openldap"
  }
}
