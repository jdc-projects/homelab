resource "kubernetes_service" "ocis_service" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "ocis"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "ocis_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "ocis"
      namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`owncloud.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.ocis_service.metadata[0].name
          namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
          port      = kubernetes_service.ocis_service.spec[0].port[0].port
        }]
      }]
    }
  }
}
