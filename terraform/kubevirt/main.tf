terraform {
  backend "kubernetes" {
    secret_suffix = "kubevirt"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubectl = {
      source = "alekc/kubectl"
      version = "2.0.4"
    }
  }
}

provider "kubectl" {
  config_path = "../cluster.yml"
}

locals {
  kubevirt_version = "v1.4.0"
}
