resource "kubernetes_service" "affine" {
  metadata {
    name      = "affine"
    namespace = kubernetes_namespace.affine.metadata[0].name
  }

  spec {
    selector = {
      app = "affine"
    }

    port {
      port        = kubernetes_config_map.affine_env.data.AFFINE_SERVER_PORT
      target_port = kubernetes_config_map.affine_env.data.AFFINE_SERVER_PORT
    }
  }
}

resource "kubernetes_manifest" "affine_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "affine"
      namespace = kubernetes_namespace.affine.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${kubernetes_config_map.affine_env.data.AFFINE_SERVER_HOST}`)"
        services = [{
          name      = kubernetes_service.affine.metadata[0].name
          namespace = kubernetes_namespace.affine.metadata[0].name
          port      = kubernetes_service.affine.spec[0].port[0].port
        }]
      }]
    }
  }
}
