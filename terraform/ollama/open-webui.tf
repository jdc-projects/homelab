locals {
  open_webui_domain = "ai.${var.server_base_domain}"
}

resource "kubernetes_config_map" "open_webui_env" {
  metadata {
    name      = "open-webui-env"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  data = {
    ENV                          = "prod"
    WEBUI_URL                    = "https://${local.open_webui_domain}"
    PORT                         = 8080
    OLLAMA_BASE_URL              = "http://${kubernetes_service.ollama.metadata[0].name}:11434"
    OPENAI_API_BASE_URL          = "http://${kubernetes_service.pipelines.metadata[0].name}:9099"
    ENABLE_SIGNUP                = "False"
    ENABLE_LOGIN_FORM            = "False"
    ENABLE_OAUTH_SIGNUP          = "True"
    OAUTH_USERNAME_CLAIM         = "name"
    OAUTH_EMAIL_CLAIM            = "email"
    OAUTH_CLIENT_ID              = keycloak_openid_client.ollama.client_id
    OAUTH_PROVIDER_NAME          = "Keycloak"
    ENABLE_OAUTH_ROLE_MANAGEMENT = "True"
    OAUTH_ROLES_CLAIM            = "roles"
    OAUTH_ALLOWED_ROLES          = "${keycloak_role.ollama_admin.name},${keycloak_role.ollama_user.name}"
    OAUTH_ADMIN_ROLES            = keycloak_role.ollama_admin.name
    OPENID_PROVIDER_URL          = "${data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url}/.well-known/openid-configuration"
    GLOBAL_LOG_LEVEL             = "INFO"
  }
}

resource "kubernetes_secret" "open_webui_env" {
  metadata {
    name      = "open-webui-env"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  data = {
    OPENAI_API_KEY      = random_password.pipelines_api_key.result
    WEBUI_SECRET_KEY    = random_password.open_webui_secret_key.result
    DATABASE_URL        = "postgresql://${random_password.open_webui_db_username.result}:${random_password.open_webui_db_password.result}@${kubernetes_manifest.open_webui_db.manifest.metadata.name}-rw:5432/${kubernetes_manifest.open_webui_db.manifest.spec.bootstrap.initdb.database}"
    OAUTH_CLIENT_SECRET = random_password.keycloak_client_secret.result
  }
}

resource "kubernetes_deployment" "open_webui" {
  metadata {
    name      = "open-webui"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "open-webui"
      }
    }

    template {
      metadata {
        labels = {
          app = "open-webui"
        }
      }

      spec {
        container {
          image = "ghcr.io/open-webui/open-webui:0.5.7"
          name  = "open-webui"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.open_webui_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.open_webui_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/app/backend/data"
            name       = "open-webui-data"
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }

            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
          }
        }

        volume {
          name = "open-webui-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ollama["open-webui"].metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.open_webui_env,
      kubernetes_secret.open_webui_env,
    ]
  }
}
