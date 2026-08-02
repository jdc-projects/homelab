terraform {
  backend "kubernetes" {
    secret_suffix = "valkey-operator"
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

# Placeholder namespace for the Valkey operator (not yet deployed). For now this
# module only hosts the centralized Valkey/Redis dashboard, which covers all
# Valkey instances cluster-wide (n8n, outline, posthog) via redis_* metrics.
resource "kubernetes_namespace" "valkey_operator" {
  metadata {
    name = "valkey-operator"
  }
}
