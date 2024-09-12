resource "kubernetes_service" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.whoami.metadata[0].name
  }

  spec {
    selector = {
      app = "whoami"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "whoami_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "whoami"
      namespace = kubernetes_namespace.whoami.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`whoami.${var.server_base_domain}`)"

        services = [{
          name      = kubernetes_service.whoami.metadata[0].name
          namespace = kubernetes_namespace.whoami.metadata[0].name
          port      = kubernetes_service.whoami.spec[0].port[0].port
        }]

        middlewares = [
          {
            name      = "cloudflare-real-ip"
            namespace = "traefik"
          },
          {
            name      = "geoblock"
            namespace = "traefik"
          },
          {
            name      = "crowdsec-bouncer"
            namespace = "traefik"
          },
        ]
      }]
    }
  }
}
