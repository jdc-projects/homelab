locals {
  temporal_ui_config = {
    TEMPORAL_ADDRESS              = "${var.name_prefix}:7233"
    TEMPORAL_UI_PORT              = "8080"
    TEMPORAL_CORS_ORIGINS         = coalesce(var.cors_origins, "")
    TEMPORAL_CSRF_COOKIE_INSECURE = "true"
  }
}

resource "kubernetes_config_map" "temporal_ui_config" {
  metadata {
    name      = "${var.name_prefix}-ui-config"
    namespace = var.namespace
  }

  data = local.temporal_ui_config
}

resource "kubernetes_deployment" "temporal_ui" {
  metadata {
    name      = "${var.name_prefix}-ui"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.name_prefix}-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.name_prefix}-ui"
        }
      }

      spec {
        container {
          image = var.ui_image
          name  = "${var.name_prefix}-ui"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.temporal_ui_config.metadata[0].name
            }
          }

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "temporal_ui" {
  metadata {
    name      = "${var.name_prefix}-ui"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "${var.name_prefix}-ui"
    }

    port {
      port        = 8080
      target_port = 8080
    }
  }
}

module "temporal_ui_ingress" {
  count  = var.ui_domain != null ? 1 : 0
  source = "../ingress"

  name                       = "${var.name_prefix}-ui"
  namespace                  = var.namespace
  domain                     = var.ui_domain
  existing_service_name      = kubernetes_service.temporal_ui.metadata[0].name
  existing_service_namespace = var.namespace
  target_port                = 8080

  auth_mode           = "oidc-interactive"
  keycloak_auth_realm = "master"
}
