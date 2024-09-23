terraform {
  backend "kubernetes" {
    secret_suffix = "knative-operator"
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
