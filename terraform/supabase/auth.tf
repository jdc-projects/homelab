resource "kubernetes_config_map" "auth_env" {
  metadata {
    name      = "auth-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    GOTRUE_API_HOST               = "0.0.0.0"
    GOTRUE_API_PORT               = "9999"
    API_EXTERNAL_URL              = local.API_EXTERNAL_URL
    GOTRUE_DB_DRIVER              = "postgres"
    GOTRUE_SITE_URL               = local.SITE_URL
    GOTRUE_URI_ALLOW_LIST         = local.ADDITIONAL_REDIRECT_URLS
    GOTRUE_DISABLE_SIGNUP         = local.DISABLE_SIGNUP
    GOTRUE_JWT_ADMIN_ROLES        = "service_role"
    GOTRUE_JWT_AUD                = "service_role"
    GOTRUE_JWT_DEFAULT_GROUP_NAME = "authenticated"
    GOTRUE_JWT_EXP                = local.JWT_EXPIRY
    GOTRUE_EXTERNAL_EMAIL_ENABLED = local.ENABLE_EMAIL_SIGNUP
    GOTRUE_MAILER_AUTOCONFIRM     = local.ENABLE_EMAIL_AUTOCONFIRM
    # GOTRUE_MAILER_SECURE_EMAIL_CHANGE_ENABLED = "true"
    # GOTRUE_SMTP_MAX_FREQUENCY = "1s"
    GOTRUE_SMTP_ADMIN_EMAIL             = local.SMTP_ADMIN_EMAIL
    GOTRUE_SMTP_HOST                    = var.smtp_host
    GOTRUE_SMTP_PORT                    = var.smtp_port
    GOTRUE_SMTP_USER                    = var.smtp_username
    GOTRUE_SMTP_SENDER_NAME             = local.SMTP_SENDER_NAME
    GOTRUE_MAILER_URLPATHS_INVITE       = local.MAILER_URLPATHS_INVITE
    GOTRUE_MAILER_URLPATHS_CONFIRMATION = local.MAILER_URLPATHS_CONFIRMATION
    GOTRUE_MAILER_URLPATHS_RECOVERY     = local.MAILER_URLPATHS_RECOVERY
    GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE = local.MAILER_URLPATHS_EMAIL_CHANGE
    GOTRUE_EXTERNAL_PHONE_ENABLED       = local.ENABLE_PHONE_SIGNUP
    GOTRUE_SMS_AUTOCONFIRM              = local.ENABLE_PHONE_AUTOCONFIRM
  }
}

resource "kubernetes_secret" "auth_env" {
  metadata {
    name      = "auth-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    GOTRUE_DB_DATABASE_URL = "postgres://supabase_auth_admin:${random_password.db_password.result}@${kubernetes_service.db.metadata[0].name}:${kubernetes_service.db.spec[0].port[0].port}/${kubernetes_config_map.db_env.data.PGDATABASE}"
    GOTRUE_JWT_SECRET      = random_password.jwt_secret.result
    GOTRUE_SMTP_PASS       = var.smtp_password
  }
}

resource "kubernetes_deployment" "auth" {
  metadata {
    name      = "auth"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "auth"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "auth"
        }
      }

      spec {
        container {
          image = "supabase/gotrue:v2.99.0"
          name  = "auth"

          liveness_probe {
            http_get {
              path = "/health"
              port = kubernetes_config_map.auth_env.data.GOTRUE_API_PORT
            }

            initial_delay_seconds = 5
            period_seconds        = 5
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.auth_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.auth_env.metadata[0].name
            }
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }

  depends_on = [
    kubernetes_deployment.db,
    kubernetes_deployment.analytics
  ]
}

resource "kubernetes_service" "auth" {
  metadata {
    name      = "auth"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "auth"
    }

    port {
      port        = 80
      target_port = kubernetes_config_map.auth_env.data.GOTRUE_API_PORT
    }
  }
}
