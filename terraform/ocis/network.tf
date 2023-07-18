resource "kubernetes_service" "ocis" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  spec {
    selector = {
      app = "ocis"
    }

    port {
      port        = "9200"
      target_port = "9200"
    }
  }
}

resource "kubernetes_manifest" "ocis_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "ocis"
      namespace = kubernetes_namespace.ocis.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`files.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.ocis.metadata[0].name
          namespace = kubernetes_namespace.ocis.metadata[0].name
          port      = kubernetes_service.ocis.spec[0].port[0].port
        }]
      }]
    }
  }
}
