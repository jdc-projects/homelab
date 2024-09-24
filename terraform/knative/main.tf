terraform {
  backend "kubernetes" {
    secret_suffix = "knative"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }

    kubectl = {
      source = "alekc/kubectl"
      version = "2.0.4"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

provider "kubectl" {
  config_path = "../cluster.yml"
}

resource "kubernetes_namespace" "knative" {
  for_each = toset([
    "serving",
    "eventing",
  ])

  metadata {
    name = "knative-${each.value}"
  }

  timeouts {
    delete = "10m"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

locals {
  knative_serving_version = "1.15.2"
  knative_eventing_version = "1.15.1"
  net_gateway_api_version = "1.15.1"
}
