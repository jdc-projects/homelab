resource "kubernetes_config_map" "penpot_exporter_env" {
  metadata {
    name      = "penpot-exporter-env"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  data = {
    PENPOT_PUBLIC_URI = "https://${local.penpot_domain}"
  }
}

resource "kubernetes_deployment" "penpot_exporter" {
  metadata {
    name      = "penpot-exporter"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "penpot-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "penpot-exporter"
        }
      }

      spec {
        container {
          image = "penpotapp/exporter:${local.penpot_version}"
          name  = "penpot-exporter"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.penpot_exporter_env.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.penpot_exporter_env,
      kubernetes_secret.penpot_exporter_env,
    ]
  }
}
