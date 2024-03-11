resource "kubernetes_service" "outline" {
  metadata {
    name      = "outline"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  spec {
    selector = {
      app = "outline"
    }

    port {
      port        = 80
      target_port = kubernetes_config_map.outline_env.data.PORT
    }
  }
}

resource "kubernetes_manifest" "outline_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "outline"
      namespace = kubernetes_namespace.outline.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${local.outline_domain}`)"
        services = [{
          name      = kubernetes_service.outline.metadata[0].name
          namespace = kubernetes_namespace.outline.metadata[0].name
          port      = kubernetes_service.outline.spec[0].port[0].port
        }]
      }]
    }
  }
}
