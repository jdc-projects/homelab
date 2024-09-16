resource "random_password" "keycloak_auth_client_secret" {
  count = var.do_enable_keycloak_auth ? 1 : 0

  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "keycloak_openid_client" "keycloak_auth" {
  count = var.do_enable_keycloak_auth ? 1 : 0

  realm_id  = var.is_keycloak_auth_admin_mode ? data.terraform_remote_state.keycloak.outputs.master_realm_id : data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = var.name

  name    = var.name
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${var.domain}/*",
  ]
  web_origins = [
    "https://${var.domain}",
  ]

  client_authenticator_type = "client-secret"
  client_secret             = one(random_password.keycloak_auth_client_secret[*].result)

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}

resource "kubernetes_manifest" "keycloak_auth_plugin_middleware" {
  count = var.do_enable_keycloak_auth ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "${var.name}-keycloak-auth"
      namespace = var.namespace
    }

    spec = {
      plugin = {
        keycloak-auth = {
          KeycloakURL   = data.terraform_remote_state.keycloak.outputs.keycloak_url
          ClientID      = one(keycloak_openid_client.keycloak_auth[*].client_id)
          ClientSecret  = one(keycloak_openid_client.keycloak_auth[*].client_secret)
          KeycloakRealm = one(keycloak_openid_client.keycloak_auth[*].realm_id)
        }
      }
    }
  }
}
