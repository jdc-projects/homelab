resource "random_password" "vaultwarden_admin_token" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_config_map" "vaultwarden_configmap" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  data = {
    WEBSOCKET_ENABLED        = "true"
    WEBSOCKET_PORT           = "3012"
    EMERGENCY_ACCESS_ALLOWED = "false"
    SIGNUPS_ALLOWED          = "false"
    SIGNUPS_VERIFY           = "false"
    INVITATIONS_ALLOWED      = "false"
    PASSWORD_HINTS_ALLOWED   = "false"
    DOMAIN                   = "https://vault.${var.server_base_domain}"
    ROCKET_PORT              = "80"
    SMTP_HOST                = var.smtp_host
    SMTP_FROM                = "noreply@${var.server_base_domain}"
    SMTP_PORT                = var.smtp_port
    SMTP_SECURITY            = "starttls"
    SMTP_USERNAME            = var.smtp_username
  }
}

resource "kubernetes_secret" "vaultwarden_secret" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  data = {
    SMTP_PASSWORD = var.smtp_password
    ADMIN_TOKEN   = random_password.vaultwarden_admin_token.result
  }
}

resource "kubernetes_deployment" "vaultwarden_deployment" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
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
          image = "vaultwarden/server:1.28.0"
          name  = "vaultwarden"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.vaultwarden_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.vaultwarden_secret
            }
          }

          volume_mount {
            mount_path = "/data"
            name       = "vaultwarden-data"
          }
        }

        volume {
          name = "vaultwarden-data"

          host_path {
            path = truenas_dataset.vaultwarden_dataset.mount_point
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.vaultwarden_configmap
    ]
  }
}
