resource "kubernetes_manifest" "cloudflare_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "cloudflare"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        cloudflare = {
          allowedCIDRs = [
            "192.168.100.0/24",
          ]
        }
      }
    }
  }
}
