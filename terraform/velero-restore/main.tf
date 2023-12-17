terraform {
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

data "terraform_remote_state" "velero" {
  backend = "kubernetes"

  config = {
    secret_suffix = "velero"
    config_path   = "../cluster.yml"
    namespace     = "terraform-state"
  }
}
