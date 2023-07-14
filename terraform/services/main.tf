terraform {
  backend "kubernetes" {
    secret_suffix = "services"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}
