resource "kubernetes_deployment" "prowler_api" {
  metadata {
    name      = "prowler-api"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prowler-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "prowler-api"
        }
      }

      spec {
        container {
          image = "prowlercloud/prowler-api:${local.prowler_version}"
          name  = "prowler-api"

          command = [
            "/home/prowler/docker-entrypoint.sh",
            "prod",
          ]

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

          volume_mount {
            mount_path = kubernetes_config_map.prowler_env.data.DJANGO_TMP_OUTPUT_DIRECTORY
            name       = "prowler-api-output"
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

        volume {
          name = "prowler-api-output"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.prowler_api_output.metadata[0].name
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

module "prowler_api_ingress" {
  source = "../modules/ingress"

  name      = "prowler-api"
  namespace = kubernetes_namespace.prowler.metadata[0].name
  domain    = local.prowler_domain

  target_port = kubernetes_config_map.prowler_env.data.DJANGO_PORT

  path = "api"

  priority = 2000

  do_enable_keycloak_auth = true

  selector = {
    app = "prowler-api"
  }
}

module "prowler_admin_ingress" {
  source = "../modules/ingress"

  name      = "prowler-admin"
  namespace = kubernetes_namespace.prowler.metadata[0].name
  domain    = local.prowler_domain

  target_port = kubernetes_config_map.prowler_env.data.DJANGO_PORT

  path = "admin"

  priority = 2000

  do_enable_keycloak_auth = true

  selector = {
    app = "prowler-api"
  }
}
