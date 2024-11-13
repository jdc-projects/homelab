resource "kubernetes_service" "ollama" {
  metadata {
    name      = "ollama"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  spec {
    selector = {
      app = "ollama"
    }

    port {
      port        = 11434
      target_port = 11434
    }
  }
}

resource "kubernetes_service" "pipelines" {
  metadata {
    name      = "pipelines"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  spec {
    selector = {
      app = "pipelines"
    }

    port {
      port        = 9099
      target_port = 9099
    }
  }
}

module "open_webui_ingress" {
  source = "../modules/ingress"

  name      = "open-webui"
  namespace = kubernetes_namespace.ollama.metadata[0].name
  domain    = local.open_webui_domain

  target_port = kubernetes_config_map.open_webui_env.data.PORT

  selector = {
    app = "open-webui"
  }
}
