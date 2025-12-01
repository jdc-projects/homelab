terraform {
  backend "kubernetes" {
    secret_suffix = "kubevirt-operator"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}

provider "kubectl" {
  config_path = "../cluster.yml"
}

locals {
  kubevirt_version = "v1.6.3"
  cdi_version      = "v1.63.1"
}
