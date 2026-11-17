terraform {
  backend "kubernetes" {
    secret_suffix = "github-org-runners"
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

resource "kubernetes_namespace" "github_org_runners" {
  metadata {
    name = "github-org-runners"

    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
  }
}

locals {
  arc_version = "0.15.1"

  # Auto-update is disabled in the runner image (DISABLE_RUNNER_UPDATE), so this
  # pin is a hard deadline: GitHub stops dispatching jobs to runners once a
  # version passes its runtime deprecation date. Check with:
  #   gh api /repos/jdc-projects/homelab/actions/runners/deprecations/<version>
  # (2.338.1 expires 2027-01-04; keep this within ~30 days of each upstream
  # actions/runner release and rebuild the image in jdc-projects/runner).
  runner_version = "2.338.2"
}
