terraform {
  backend "kubernetes" {
    secret_suffix = "kubevirt-operator"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.4.1"
    }

    http = {
      source  = "hashicorp/http"
      version = "3.6.0"
    }
  }
}

provider "kubectl" {
  config_path = "../cluster.yml"
}

locals {
  kubevirt_version = "v1.8.4"
  cdi_version      = "v1.65.0"
}
