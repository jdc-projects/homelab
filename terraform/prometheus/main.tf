terraform {
  backend "kubernetes" {
    secret_suffix = "prometheus"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = "../cluster.yml"
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

# Reads the pinned chart version from the operator module so both installs
# always match - the CRDs installed by terraform/prometheus-operator/ must
# be the same version the instance module templates against.
data "terraform_remote_state" "prometheus_operator" {
  backend = "kubernetes"

  config = {
    secret_suffix = "prometheus-operator"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}
