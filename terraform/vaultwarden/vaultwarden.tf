resource "kubernetes_config_map" "vaultwarden_env" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    WEBSOCKET_ENABLED        = "false" # this doesn't disable live sync, it just disables the old, separate websocket server
    EMERGENCY_ACCESS_ALLOWED = "false"
    SIGNUPS_ALLOWED          = "false"
    SIGNUPS_VERIFY           = "false"
    INVITATIONS_ALLOWED      = "true"
    PASSWORD_HINTS_ALLOWED   = "true"
    DOMAIN                   = "https://vault.${var.server_base_domain}"
    ROCKET_PORT              = "80"
    SMTP_HOST                = var.smtp_host
    SMTP_FROM                = "noreply@${var.server_base_domain}"
    SMTP_PORT                = var.smtp_port
    SMTP_SECURITY            = "force_tls"
    SMTP_USERNAME            = var.smtp_username
    PUSH_ENABLED             = "true"
    PUSH_RELAY_URI           = "https://push.bitwarden.${var.is_vaultwarden_push_data_region_us ? "com" : "eu"}"
    PUSH_IDENTITY_URI        = "https://identity.bitwarden.${var.is_vaultwarden_push_data_region_us ? "com" : "eu"}"
  }
}

resource "kubernetes_secret" "vaultwarden_env" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    SMTP_PASSWORD         = var.smtp_password
    ADMIN_TOKEN           = random_password.vaultwarden_admin_token.result
    DATABASE_URL          = "postgresql://${random_password.vaultwarden_db_username.result}:${random_password.vaultwarden_db_password.result}@${kubernetes_manifest.vaultwarden_db.manifest.metadata.name}-rw:5432/${kubernetes_manifest.vaultwarden_db.manifest.spec.bootstrap.initdb.database}"
    PUSH_INSTALLATION_ID  = var.vaultwarden_push_installation_id
    PUSH_INSTALLATION_KEY = var.vaultwarden_push_installation_key
  }
}

resource "kubernetes_deployment" "vaultwarden_deployment" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vaultwarden"
      }
    }

    template {
      metadata {
        labels = {
          app = "vaultwarden"
        }
      }

      spec {
        container {
          image = "vaultwarden/server:1.30.5-alpine"
          name  = "vaultwarden"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.vaultwarden_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.vaultwarden_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/data"
            name       = "vaultwarden-data"
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

        volume {
          name = "vaultwarden-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.vaultwarden.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.vaultwarden_env,
      kubernetes_secret.vaultwarden_env
    ]
  }
}
