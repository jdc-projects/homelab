locals {
  penpot_domain  = "penpot.${var.server_base_domain}"
  penpot_version = "2.0.3"
  penpot_shared_flags = join(" ", [
    "disable-registration",
    "disable-login-with-password",
    "enable-login-with-oidc",
    "enable-smtp",
    "disable-onboarding-questions",
  ])
}

resource "kubernetes_config_map" "penpot_frontend_env" {
  metadata {
    name      = "penpot-frontend-env"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  data = {
    PENPOT_FLAGS        = local.penpot_shared_flags
    PENPOT_BACKEND_URI  = "http://${kubernetes_service.penpot_backend.metadata[0].name}"
    PENPOT_EXPORTER_URI = "http://${kubernetes_service.penpot_exporter.metadata[0].name}"
  }
}

resource "kubernetes_deployment" "penpot_frontend" {
  metadata {
    name      = "penpot-frontend"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "penpot-frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "penpot-frontend"
        }
      }

      spec {
        container {
          image = "penpotapp/frontend:${local.penpot_version}"
          name  = "penpot-frontend"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.penpot_frontend_env.metadata[0].name
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
      kubernetes_config_map.penpot_frontend_env,
    ]
  }

  depends_on = [
    kubernetes_deployment.penpot_backend,
    kubernetes_deployment.penpot_exporter,
  ]
}
