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

module "penpot_frontend_ingress" {
  source = "../modules/ingress"

  name      = "penpot-frontend"
  namespace = kubernetes_namespace.penpot.metadata[0].name
  domain    = local.penpot_domain

  target_port = 80

  selector = {
    app = "penpot-frontend"
  }
}
