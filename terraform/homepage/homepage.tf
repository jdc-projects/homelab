resource "kubernetes_config_map" "homepage_env" {
  metadata {
    name      = "homepage"
    namespace = kubernetes_namespace.homepage.metadata[0].name
  }

  data = {
    NODE_ENV               = "production"
    LOG_TARGETS            = "stdout"
    HOMEPAGE_ALLOWED_HOSTS = "apps.${var.server_base_domain}"
  }
}

resource "kubernetes_secret" "homepage_env" {
  metadata {
    name      = "homepage"
    namespace = kubernetes_namespace.homepage.metadata[0].name
  }

  data = {
  }
}

resource "kubernetes_deployment" "homepage" {
  metadata {
    name      = "homepage"
    namespace = kubernetes_namespace.homepage.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "homepage"
      }
    }

    template {
      metadata {
        labels = {
          app = "homepage"
        }
      }

      spec {
        container {
          image = "ghcr.io/gethomepage/homepage:v1.13.2"
          name  = "homepage"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.homepage_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.homepage_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "config-yamls"
            mount_path = "/app/config"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "config-yamls"

          config_map {
            name = kubernetes_config_map.homepage_config_yamls.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.homepage_config_yamls,
    ]
  }
}

module "homepage_ingress" {
  source = "../modules/ingress"

  name        = "homepage"
  namespace   = kubernetes_namespace.homepage.metadata[0].name
  domain      = kubernetes_config_map.homepage_env.data.HOMEPAGE_ALLOWED_HOSTS
  target_port = 3000
  selector = {
    app = "homepage"
  }

  auth_mode = "oidc-interactive"
}
