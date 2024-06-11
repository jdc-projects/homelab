locals {
  grist_domain = "grist.${var.server_base_domain}"
}

resource "kubernetes_config_map" "grist_env" {
  metadata {
    name      = "grist-env"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  data = {
    # ALLOWED_WEBHOOK_DOMAINS = local.grist_domain
    APP_HOME_URL            = "https://${local.grist_domain}"
    # GRIST_HIDE_UI_ELEMENTS         = "billing" # ***** may need some more here, see 'GRIST_UI_FEATURES'
    GRIST_HOST                     = "0.0.0.0"
    GRIST_MAX_UPLOAD_ATTACHMENT_MB = 0 # unlimited
    GRIST_MAX_UPLOAD_IMPORT_MB     = 0 # unlimited
    GRIST_ANON_PLAYGROUND          = "false"
    GRIST_FORCE_LOGIN              = "true"
    GRIST_TELEMETRY_LEVEL          = "off"
    # GRIST_UI_FEATURES = "helpCenter,billing,templates,createSite,multiSite,multiAccounts,sendToDrive,tutorials"
    HOME_PORT = "share"
    PORT                 = 8484
    GRIST_SANDBOX_FLAVOR = "gvisor"
    # GRIST_SANDBOX = ""
    PYTHON_VERSION             = "3"
    PYTHON_VERSION_ON_CREATION = "3"
    TYPEORM_DATABASE           = kubernetes_manifest.grist_db.manifest.spec.bootstrap.initdb.database
    TYPEORM_HOST               = "${kubernetes_manifest.grist_db.manifest.metadata.name}-rw" # "postgres-debug"
    TYPEORM_LOGGING            = "true" # *****
    TYPEORM_PORT               = 5432
    TYPEORM_TYPE               = "postgres"
    GRIST_OIDC_IDP_ISSUER      = "${data.terraform_remote_state.keycloak_config.outputs.keycloak_url}/realms/${data.terraform_remote_state.keycloak_config.outputs.primary_realm_id}"
    GRIST_OIDC_IDP_CLIENT_ID   = keycloak_openid_client.grist.name
    GRIST_DOCS_MINIO_BUCKET    = local.minio_bucket_name
    GRIST_DOCS_MINIO_ENDPOINT  = helm_release.minio.name
    GRIST_DOCS_MINIO_USE_SSL   = 0 # 1 https, 0 http
    GRIST_DOCS_MINIO_PORT      = 9000

    COOKIE_MAX_AGE = 86400000

    # GRIST_SINGLE_ORG  = "organization-name"
    # GRIST_ORG_IN_PATH = "true"

    GRIST_DOMAIN = local.grist_domain
  }
}

resource "kubernetes_secret" "grist_env" {
  metadata {
    name      = "grist-env"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  data = {
    GRIST_SESSION_SECRET = random_password.grist_session_secret.result
    REDIS_URL                    = "redis://:${random_password.grist_redis_password.result}@${helm_release.redis.name}-master:6379"
    TYPEORM_PASSWORD             = random_password.grist_db_password.result
    TYPEORM_USERNAME             = random_password.grist_db_username.result
    GRIST_OIDC_IDP_CLIENT_SECRET = random_password.keycloak_client_secret.result
    GRIST_DOCS_MINIO_ACCESS_KEY  = random_password.minio_access_key.result
    GRIST_DOCS_MINIO_SECRET_KEY  = random_password.minio_secret_key.result
  }
}

resource "kubernetes_deployment" "grist" {
  metadata {
    name      = "grist"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "grist"
      }
    }

    template {
      metadata {
        labels = {
          app = "grist"
        }
      }

      spec {
        container {
          image = "gristlabs/grist:1.1.14"
          name  = "grist"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.grist_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.grist_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/persist"
            name       = "grist-data"
          }

          # resources {
          #   requests = {
          #     cpu    = "500m"
          #     memory = "512Mi"
          #   }

          #   limits = {
          #     cpu    = "1"
          #     memory = "1Gi"
          #   }
          # }
        }

        volume {
          name = "grist-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.grist.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.grist_env,
      kubernetes_secret.grist_env,
    ]
  }
}
