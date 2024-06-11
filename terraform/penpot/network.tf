resource "kubernetes_service" "penpot_frontend" {
  metadata {
    name      = "penpot-frontend"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  spec {
    selector = {
      app = "penpot-frontend"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_service" "penpot_backend" {
  metadata {
    name      = "penpot-backend"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  spec {
    selector = {
      app = "penpot-backend"
    }

    port {
      port        = 80
      target_port = kubernetes_config_map.penpot_backend_env.data.PENPOT_HTTP_SERVER_PORT
    }
  }
}

resource "kubernetes_service" "penpot_exporter" {
  metadata {
    name      = "penpot-exporter"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  spec {
    selector = {
      app = "penpot-exporter"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "penpot_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "penpot"
      namespace = kubernetes_namespace.penpot.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${local.penpot_domain}`)"
        services = [{
          name      = kubernetes_service.penpot_frontend.metadata[0].name
          namespace = kubernetes_namespace.penpot.metadata[0].name
          port      = kubernetes_service.penpot_frontend.spec[0].port[0].port
        }]
      }]
    }
  }
}
