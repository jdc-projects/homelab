terraform {
  backend "kubernetes" {
    secret_suffix = "github-org-runners-2"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"

    labels = {
      "velero.io/exclude-from-backup" = "true"
    }
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
  }
}

data "terraform_remote_state" "github_org_runners_1" {
  backend = "kubernetes"

  config = {
    secret_suffix = "github-org-runners-1"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

provider "kubernetes" {
  config_path = "../cluster.yml"
}
