resource "kubernetes_service" "grist" {
  metadata {
    name      = "grist"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    selector = {
      app = "grist"
    }

    port {
      port        = 80
      target_port = kubernetes_config_map.grist_env.data.PORT
    }
  }
}

resource "kubernetes_manifest" "grist_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "grist"
      namespace = kubernetes_namespace.grist.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${local.grist_domain}`)"
        services = [{
          name      = kubernetes_service.grist.metadata[0].name
          namespace = kubernetes_namespace.grist.metadata[0].name
          port      = kubernetes_service.grist.spec[0].port[0].port
        }]
      }]
    }
  }
}
