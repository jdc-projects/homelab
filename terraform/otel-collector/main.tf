terraform {
  backend "kubernetes" {
    secret_suffix = "otel-collector"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}

# The `otel` namespace is owned by terraform/otel-operator/. This module deploys
# only the OpenTelemetryCollector CR (and its ServiceMonitor) into it; deploy
# ordering in .github/workflows/deploy.yml ensures deploy-otel-operator runs
# before deploy-otel-collector.
locals {
  namespace = "otel"
}
