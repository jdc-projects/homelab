locals {
  web_check_domain = "web-check.${var.server_base_domain}"
}

resource "kubernetes_config_map" "web_check_env" {
  metadata {
    name      = "web-check-env"
    namespace = kubernetes_namespace.web_check.metadata[0].name
  }

  data = {
    PORT        = "3000"
    TRUST_PROXY = "1"
  }
}

resource "kubernetes_deployment" "web_check" {
  metadata {
    name      = "web-check"
    namespace = kubernetes_namespace.web_check.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "web-check"
      }
    }

    template {
      metadata {
        labels = {
          app = "web-check"
        }
      }

      spec {
        container {
          image = "lissy93/web-check:2.1.9"
          name  = "web-check"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.web_check_env.metadata[0].name
            }
          }

          port {
            container_port = 3000
            name           = "http"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }

            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }

            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.web_check_env,
    ]
  }
}

module "web_check_ingress" {
  source = "../modules/ingress"

  name      = "web-check"
  namespace = kubernetes_namespace.web_check.metadata[0].name
  domain    = local.web_check_domain

  target_port = 3000

  do_enable_keycloak_auth = true

  selector = {
    app = "web-check"
  }
}
