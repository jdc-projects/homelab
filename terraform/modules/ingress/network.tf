resource "kubernetes_service" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = var.selector

    port {
      port        = 80
      target_port = var.target_port
    }
  }
}

resource "kubernetes_manifest" "ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = var.name
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${var.domain}`)${"" != var.path ? " && PathPrefix(`/${var.path}/`)" : ""}"

        services = [{
          name      = kubernetes_service.service.metadata[0].name
          namespace = var.namespace
          port      = kubernetes_service.service.spec[0].port[0].port
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
