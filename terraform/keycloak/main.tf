terraform {
  backend "kubernetes" {
    secret_suffix = "apps-keycloak"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }

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

    archive = {
      source  = "hashicorp/archive"
      version = "2.4.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../../cluster.yml"
  }
}

provider "kubernetes" {
  config_path = "../../cluster.yml"
}

provider "null" {
  # Configuration options
}

provider "random" {
}

provider "archive" {
  # Configuration options
}

resource "kubernetes_namespace" "keycloak_namespace" {
  metadata {
    name = "keycloak"
  }
}
