resource "kubernetes_manifest" "cloudflarewarp_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "cloudflare-real-ip"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        cloudflare-real-ip = {
          disableDefault = "false"
        }
      }
    }
  }
}
