terraform {
  backend "kubernetes" {
    secret_suffix = "knative"
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

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }

    # Required by the shared ingress module (used by the Tier-2 test fn); only
    # actually invoked when auth_mode is an oidc mode. Mirrors iac/13ft.
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.8"
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

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

locals {
  # Pinned to the latest minor the Knative Operator (v1.22.3) ships. The
  # operator resolves this to the latest matching patch. Knative components are
  # kept on the same minor.
  knative_version = "1.22"

  # The Traefik Knative provider's ingress class (Knative convention:
  # <name>.ingress.networking.knative.dev). Must match the provider enabled in
  # iac/traefik.
  ingress_class = "traefik.ingress.networking.knative.dev"
}

resource "kubernetes_namespace" "knative_serving" {
  metadata {
    name = "knative-serving"
  }
}

resource "kubernetes_namespace" "knative_eventing" {
  metadata {
    name = "knative-eventing"
  }
}

# Defensive: ensure the operator CRDs are Established before the
# KnativeServing/KnativeEventing manifests apply. They normally already are (the
# operator deploys in its own job/module first), but this guards a back-to-back
# local apply of both modules and surfaces a clear wait instead of a CRD race.
resource "null_resource" "wait_for_operator_crds" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=established --timeout=300s crd/knativeservings.operator.knative.dev || true
      kubectl wait --for=condition=established --timeout=300s crd/knativeeventings.operator.knative.dev || true
    EOT
  }

  depends_on = [
    kubernetes_namespace.knative_serving,
    kubernetes_namespace.knative_eventing,
  ]
}
