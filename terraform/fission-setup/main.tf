terraform {
  backend "kubernetes" {
    secret_suffix = "fission-setup"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
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

data "terraform_remote_state" "fission" {
  backend = "kubernetes"

  config = {
    secret_suffix = "fission"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}
