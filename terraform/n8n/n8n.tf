locals {
  n8n_domain = "n8n.${var.server_base_domain}"
}

resource "kubernetes_config_map" "n8n_env" {
  metadata {
    name      = "n8n-env"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  data = {
    N8N_HOST                          = local.n8n_domain
    N8N_PORT                          = 5678
    N8N_PROTOCOL                      = "https"
    WEBHOOK_URL                       = "https://${local.n8n_domain}"
    GENERIC_TIMEZONE                  = "UTC"
    NODE_ENV                          = "production"
    N8N_METRICS                       = "true"
    N8N_DIAGNOSTICS_ENABLED           = "false"
    N8N_PERSONALIZATION_ENABLED       = "false"
    N8N_VERSION_NOTIFICATIONS_ENABLED = "false"
    N8N_TEMPLATES_ENABLED             = "true"
    QUEUE_BULL_REDIS_HOST             = helm_release.valkey.name
    QUEUE_BULL_REDIS_PORT             = "6379"
    QUEUE_BULL_REDIS_DB               = "0"
    N8N_ADDITIONAL_NON_UI_ROUTES      = "auth"
    EXTERNAL_HOOK_FILES               = "/hooks/hooks.js"
    EXTERNAL_FRONTEND_HOOKS_URLS      = "/assets/oidc-frontend-hook.js"
    OIDC_ISSUER_URL                   = data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url
    OIDC_CLIENT_ID                    = keycloak_openid_client.n8n.client_id
    OIDC_REDIRECT_URI                 = "https://${local.n8n_domain}/auth/oidc/callback"
  }
}

resource "kubernetes_secret" "n8n_env" {
  metadata {
    name      = "n8n-env"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  data = {
    N8N_ENCRYPTION_KEY     = random_password.n8n_encryption_key.result
    DB_TYPE                = "postgresdb"
    DB_POSTGRESDB_HOST     = "${kubernetes_manifest.n8n_db.manifest.metadata.name}-rw"
    DB_POSTGRESDB_PORT     = "5432"
    DB_POSTGRESDB_DATABASE = kubernetes_manifest.n8n_db.manifest.spec.bootstrap.initdb.database
    DB_POSTGRESDB_USER     = random_password.n8n_db_username.result
    DB_POSTGRESDB_PASSWORD = random_password.n8n_db_password.result
    OIDC_CLIENT_SECRET     = random_password.keycloak_client_secret.result
  }
}

resource "kubernetes_config_map" "n8n_hooks" {
  metadata {
    name      = "n8n-hooks"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  data = {
    "hooks.js" = file("${path.module}/hooks.js")
  }
}

resource "kubernetes_deployment" "n8n" {
  metadata {
    name      = "n8n"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "n8n"
      }
    }

    template {
      metadata {
        labels = {
          app = "n8n"
        }
      }

      spec {
        init_container {
          image = "alpine:3.24.1"
          name  = "n8n-chown"

          command = ["sh", "-c", "chown -R 1000:1000 /home/node/.n8n"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/home/node/.n8n"
            name       = "n8n-data"
          }
        }

        container {
          image = "n8nio/n8n:2.28.3"
          name  = "n8n"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.n8n_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.n8n_env.metadata[0].name
            }
          }

          port {
            container_port = 5678
            name           = "http"
          }

          volume_mount {
            name       = "n8n-data"
            mount_path = "/home/node/.n8n"
          }

          volume_mount {
            name       = "n8n-hooks"
            mount_path = "/hooks"
            read_only  = true
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 5678
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 5678
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

        volume {
          name = "n8n-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.n8n_data.metadata[0].name
          }
        }

        volume {
          name = "n8n-hooks"
          config_map {
            name = kubernetes_config_map.n8n_hooks.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.n8n_env,
      kubernetes_config_map.n8n_hooks,
      kubernetes_secret.n8n_env,
    ]
  }
}

module "n8n_ingress" {
  source = "../modules/ingress"

  name      = "n8n"
  namespace = kubernetes_namespace.n8n.metadata[0].name
  domain    = local.n8n_domain

  target_port = 5678

  do_enable_crowdsec_bouncer_appsec = false

  selector = {
    app = "n8n"
  }
}
