terraform {
  backend "kubernetes" {
    secret_suffix = "foundation-part2"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
  }
}

data "terraform_remote_state" "foundation_part1" {
  backend = "kubernetes"

  config = {
    secret_suffix = "foundation-part1"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }
}

provider "kubernetes" {
  config_path = "../../cluster.yml"
}
