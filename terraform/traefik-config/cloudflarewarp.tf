resource "kubernetes_manifest" "cloudflarewarp_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "cloudflarewarp"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        cloudflarewarp = {
          disableDefault = "false"
        }
      }
    }
  }
}
