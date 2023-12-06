resource "random_password" "vaultwarden_admin_token" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_config_map" "vaultwarden_env" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    WEBSOCKET_ENABLED        = "true"
    WEBSOCKET_PORT           = "3012"
    EMERGENCY_ACCESS_ALLOWED = "false"
    SIGNUPS_ALLOWED          = "false"
    SIGNUPS_VERIFY           = "false"
    INVITATIONS_ALLOWED      = "true"
    PASSWORD_HINTS_ALLOWED   = "false"
    DOMAIN                   = "https://vault.${var.server_base_domain}"
    ROCKET_PORT              = "80"
    SMTP_HOST                = var.smtp_host
    SMTP_FROM                = "noreply@${var.server_base_domain}"
    SMTP_PORT                = var.smtp_port
    SMTP_SECURITY            = "force_tls"
    SMTP_USERNAME            = var.smtp_username
  }
}

resource "kubernetes_secret" "vaultwarden_env" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    SMTP_PASSWORD = var.smtp_password
    ADMIN_TOKEN   = random_password.vaultwarden_admin_token.result
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
          image = "vaultwarden/server:1.30.1-alpine"
          name  = "vaultwarden"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.vaultwarden_env.metadata[0].name
            }

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
