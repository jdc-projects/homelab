resource "kubernetes_service" "nextcloud_service" {
  metadata {
    name      = "nextcloud"
    namespace = kubernetes_namespace.nextcloud_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "nextcloud"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "nextcloud_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "nextcloud"
      namespace = kubernetes_namespace.nextcloud_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`nextcloud.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.nextcloud_service.metadata[0].name
          namespace = kubernetes_namespace.nextcloud_namespace.metadata[0].name
          port      = kubernetes_service.nextcloud_service.spec[0].port[0].target_port
        }]
      }]
    }
  }
}
