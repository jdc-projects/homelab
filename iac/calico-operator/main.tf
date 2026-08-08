terraform {
  backend "kubernetes" {
    secret_suffix = "calico-operator"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
