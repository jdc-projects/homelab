terraform {
  backend "kubernetes" {
    secret_suffix = "coder"
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

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  password  = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  url       = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

data "terraform_remote_state" "keycloak" {
  backend = "kubernetes"

  config = {
    secret_suffix = "keycloak-config"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

# Namespace of the shared traefik middlewares (cloudflare, geoblock,
# crowdsec-bouncer) attached to the hand-rolled workspace-app wildcard route.
data "terraform_remote_state" "traefik" {
  backend = "kubernetes"

  config = {
    secret_suffix = "traefik"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

resource "kubernetes_namespace" "coder" {
  metadata {
    name = "coder"
  }
}

# Workspaces (pods + home PVCs) land here, isolated from the coderd control
# plane and its database. coderd's service account is granted
# pod/PVC/Deployment permissions in this namespace by the helm chart via the
# coder.serviceAccount.workspaceNamespaces value (see coder.tf).
resource "kubernetes_namespace" "coder_workspaces" {
  metadata {
    name = "coder-workspaces"
  }
}
