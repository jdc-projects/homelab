terraform {
  backend "kubernetes" {
    secret_suffix = "apps-external-services"
    config_path = "../../cluster.yml"
    namespace = "terraform-state"
  }

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.18.1"
    }
  }
}

provider "kubernetes" {
  config_path = "../../cluster.yml"
}
