resource "random_password" "keycloak_auth_client_secret" {
  count = var.auth_mode == "oidc-interactive" && local.auth_oidc_managed ? 1 : 0

  length  = 50
  numeric = true
  special = false
  upper   = true
}

# The plugin Secret (32-char, encrypts session/cookie state) is provider-independent - created for
# both the managed Keycloak path and the generic OIDC path.
resource "random_password" "keycloak_auth_plugin_secret" {
  count = var.auth_mode == "oidc-interactive" ? 1 : 0

  length  = 32
  special = false
}

resource "keycloak_openid_client" "keycloak_auth" {
  count = var.auth_mode == "oidc-interactive" && local.auth_oidc_managed ? 1 : 0

  realm_id  = local.keycloak_auth_realm_id
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

# TokenValidation defaults to IdToken (local JWKS signature validation), deliberately
# NOT Introspection. Keycloak 26 enforces that the introspecting client must be in the
# access token's `aud` claim; these clients use full_scope_allowed=false with no audience
# mapper, so introspection returns active:false and causes a redirect loop. IdToken
# validation sidesteps this because the ID token's `aud` is always the client id.
# If Introspection is ever needed, add a keycloak_openid_audience_protocol_mapper to
# keycloak_openid_client.keycloak_auth first.
#
# v0.21.0 note: UnauthenticatedBehavior is pinned to "Auto" explicitly. This matches the
# pre-0.21.0 effective default (the single UnauthorizedBehavior defaulted to "Auto" via
# CreateConfig), so browser-redirect behaviour is preserved: HTML requests redirect to the
# IDP login, non-HTML requests get 401. UnauthorizedBehavior (403 case) is left at its
# "Unauthorized" default.
resource "kubernetes_manifest" "keycloak_auth_plugin_middleware" {
  count = var.auth_mode == "oidc-interactive" ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "${var.name}-auth-interactive"
      namespace = var.namespace
    }

    spec = {
      plugin = {
        traefik-oidc-auth = {
          # Provider inputs switch on managed (Keycloak client) vs generic (auth_oidc_provider).
          # ClientSecret is overlaid via merge() so it's omitted entirely when null (generic +
          # PKCE-only/public client) rather than sent as null/empty, which trips the
          # kubernetes_manifest provider's post-apply validation.
          Provider = merge(
            {
              Url      = local.auth_oidc_managed ? "${data.terraform_remote_state.keycloak.outputs.keycloak_url}/realms/${one(keycloak_openid_client.keycloak_auth[*].realm_id)}" : local.auth_oidc_provider_url
              ClientId = local.auth_oidc_managed ? one(keycloak_openid_client.keycloak_auth[*].client_id) : local.auth_oidc_provider_client_id
              UsePkce  = true
            },
            local.auth_oidc_interactive_client_secret != null ? {
              ClientSecret = local.auth_oidc_interactive_client_secret
            } : {}
          )

          Scopes                  = local.auth_oidc_interactive_scopes
          Secret                  = one(random_password.keycloak_auth_plugin_secret[*].result)
          CallbackUri             = var.callback_path
          UnauthenticatedBehavior = "Auto"
        }
      }
    }
  }
}
