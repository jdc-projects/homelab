resource "kubernetes_deployment" "prowler_ui" {
  metadata {
    name      = "prowler-ui"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prowler-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "prowler-ui"
        }
      }

      spec {
        container {
          image = "prowlercloud/prowler-ui:${local.prowler_version}"
          name  = "prowler-ui"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.prowler_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.prowler_env.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.prowler_env,
      kubernetes_secret.prowler_env
    ]
  }
}

module "prowler_ui_ingress" {
  source = "../modules/ingress"

  name      = "prowler-ui"
  namespace = kubernetes_namespace.prowler.metadata[0].name
  domain    = local.prowler_domain

  target_port = kubernetes_config_map.prowler_env.data.UI_PORT

  priority = 1000

  do_enable_keycloak_auth = true

  selector = {
    app = "prowler-ui"
  }
}
