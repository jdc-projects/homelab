terraform {
  backend "kubernetes" {
    secret_suffix = "calico"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}
