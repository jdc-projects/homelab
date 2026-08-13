locals {
  vaultwarden_domain = "vault.${var.server_base_domain}"
}

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
    DOMAIN                   = "https://${local.vaultwarden_domain}"
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
          image = "vaultwarden/server:1.36.0-alpine"
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

module "vaultwarden_ingress" {
  source = "../modules/ingress"

  name      = "vaultwarden"
  namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  domain    = local.vaultwarden_domain

  target_port = kubernetes_config_map.vaultwarden_env.data.ROCKET_PORT

  selector = {
    app = "vaultwarden"
  }
}

# The admin panel (/admin) is served on the same host as the public vault.
# Unlike cap, the vaultwarden admin surface is a single clean prefix, so we keep
# the main ingress public (users log in with their master password) and put OIDC
# in front of /admin only - defense in depth on top of ADMIN_TOKEN.
#
# The regex also covers /oidc/callback: the traefik-oidc-auth plugin redirects
# there after login, and that path must route through this same OIDC middleware
# or (with a public catch-all) the code would never exchange and login breaks.
# priority 100 beats the public catch-all (auto-priority) for these paths only.
module "vaultwarden_admin_ingress" {
  source = "../modules/ingress"

  name      = "vaultwarden-admin"
  namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  domain    = local.vaultwarden_domain

  # Reuse the service created by vaultwarden_ingress (named <name>-internal).
  existing_service_name      = "vaultwarden-internal"
  existing_service_namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  target_port                = 80

  auth_mode           = "oidc-interactive"
  keycloak_auth_realm = "primary"

  path_matcher = "PathRegexp"
  path         = "^/(admin(/.*)?|oidc/callback(/.*)?)$"

  priority = 100
}
