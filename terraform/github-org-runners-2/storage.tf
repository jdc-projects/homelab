resource "kubernetes_persistent_volume_claim" "runners_cache" {
  metadata {
    name      = "runners-cache"
    namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
