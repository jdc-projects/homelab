resource "kubernetes_service" "drawio" {
  metadata {
    name      = "drawio"
    namespace = kubernetes_namespace.drawio.metadata[0].name
  }

  spec {
    selector = {
      app = "drawio"
    }

    port {
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_manifest" "drawio_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "drawio"
      namespace = kubernetes_namespace.drawio.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${local.drawio_domain}`)"
        services = [{
          name      = kubernetes_service.drawio.metadata[0].name
          namespace = kubernetes_namespace.drawio.metadata[0].name
          port      = kubernetes_service.drawio.spec[0].port[0].port
        }]
      }]
    }
  }
}
