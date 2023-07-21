resource "kubernetes_config_map" "traefik_forward_auth_env" {
  metadata {
    name      = "traefik-forward-auth-env"
    namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
  }

  data = {
    LOG_LEVEL        = "info"
    DEFAULT_ACTION   = "auth"
    DEFAULT_PROVIDER = "oidc"
    URL_PATH         = "/oauth"
    PORT             = "80"
    PROVIDER_URI     = "https://idp.${var.server_base_domain}/realms/${data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id}"
    CLIENT_ID        = keycloak_openid_client.traefik_forward_auth.client_id
  }
}

resource "kubernetes_secret" "traefik_forward_auth_env" {
  metadata {
    name      = "traefik-forward-auth-env"
    namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
  }

  data = {
    SECRET        = random_password.traefik_forward_auth_secret.result
    CLIENT_SECRET = random_password.keycloak_client_secret.result
  }
}

resource "kubernetes_deployment" "traefik-forward-auth" {
  metadata {
    name      = "traefik-forward-auth"
    namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "traefik-forward-auth"
      }
    }

    template {
      metadata {
        labels = {
          app = "traefik-forward-auth"
        }
      }

      spec {
        container {
          image = "mesosphere/traefik-forward-auth:3.1.0"
          name  = "traefik-forward-auth"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.traefik_forward_auth_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.traefik_forward_auth_env.metadata[0].name
            }
          }
        }
      }
    }
  }

  timeouts {
    create = "1m"
    update = "1m"
    delete = "1m"
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.traefik_forward_auth_env,
      kubernetes_secret.traefik_forward_auth_env
    ]
  }
}

resource "kubernetes_manifest" "traefik_forward_auth_middleware" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "traefik-forward-auth"
      namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
    }

    spec = {
      forwardAuth = {
        address             = "https://traefik-forward-auth.${var.server_base_domain}${kubernetes_config_map.traefik_forward_auth_env.data.URL_PATH}"
        authResponseHeaders = ["X-Forwarded-User"]
        trustForwardHeader  = "true"
      }
    }
  }
}
