# API/offload auth mode (oidc-api): validates a bearer token from the Authorization header against
# the OIDC provider (default: stateless JWKS signature check on the access token), injects identity
# claims as upstream headers, and returns 401/403 on failure (no redirect, no login page). Mimics
# AWS API Gateway / Azure APIM JWT validation.
#
# TokenValidation defaults to AccessToken (local JWKS). Introspection mode calls Keycloak's
# introspection endpoint per request - it catches revoked tokens but is slower and needs the client
# secret. Note the same caveat as the interactive client (comment in keycloak-auth-interactive.tf):
# Keycloak 26 requires the introspecting client to be in the access token's `aud` claim, so set
# auth_oidc_api_audience and ensure issuing clients carry it (via their own audience mappers) when
# using Introspection.
#
# Future work (generic OIDC): the auth_oidc_api_* vars here are already provider-agnostic. The only
# Keycloak-specific pieces are keycloak_auth_realm and the keycloak_openid_client + audience mapper
# below. Adding an optional auth_oidc_provider object var (null = Keycloak-managed) that, when set,
# skips client creation and passes Url/ClientId/ClientSecret through would make this generic - the
# middleware manifest itself would need no change, only its input source. Raise this once migrations
# are complete.

resource "random_password" "keycloak_auth_api_client_secret" {
  count = var.auth_mode == "oidc-api" ? 1 : 0

  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "keycloak_auth_api_plugin_secret" {
  count = var.auth_mode == "oidc-api" ? 1 : 0

  length  = 32
  special = false
}

resource "keycloak_openid_client" "keycloak_auth_api" {
  count = var.auth_mode == "oidc-api" ? 1 : 0

  realm_id  = local.keycloak_auth_realm_id
  client_id = "${var.name}-api"

  name    = "${var.name}-api"
  enabled = true

  access_type = "CONFIDENTIAL"

  # No browser login - this client exists to (a) validate bearer tokens and (b) mint service-account
  # tokens for machine-to-machine use. Service accounts allow the client_credentials grant.
  standard_flow_enabled        = false
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false
  service_accounts_enabled     = true

  full_scope_allowed = false

  client_authenticator_type = "client-secret"
  client_secret             = one(random_password.keycloak_auth_api_client_secret[*].result)

  valid_redirect_uris = []
  web_origins         = []
}

# Adds an audience to the access token's `aud` claim so the middleware's audience check passes.
# Keycloak 26 service-account (client_credentials) tokens ship WITHOUT an `aud` claim by default,
# which the plugin rejects ("token is missing required claim: aud"); this mapper ensures one is
# always present. The audience defaults to the client id (matching the middleware's ValidAudience
# default) and is overridden by auth_oidc_api_audience for cross-client validation. Note: this only
# shapes tokens minted by THIS client - tokens minted by OTHER clients need their own mappers.
resource "keycloak_openid_audience_protocol_mapper" "api_audience" {
  count = var.auth_mode == "oidc-api" ? 1 : 0

  realm_id  = local.keycloak_auth_realm_id
  client_id = one(keycloak_openid_client.keycloak_auth_api[*].id)
  name      = "${var.name}-api-audience"

  included_custom_audience = var.auth_oidc_api_audience != "" ? var.auth_oidc_api_audience : "${var.name}-api"
  add_to_access_token      = true
  add_to_id_token          = false
}

resource "kubernetes_manifest" "keycloak_auth_api_plugin_middleware" {
  count = var.auth_mode == "oidc-api" ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "${var.name}-auth-api"
      namespace = var.namespace
    }

    spec = {
      plugin = {
        # The plugin block is built with merge() so Authorization and BypassAuthenticationRule are
        # emitted ONLY when they carry content. Sending empty values (AssertClaims: [], rule: "")
        # trips the kubernetes_manifest provider's post-apply type validation ("inconsistent result")
        # because empty collections can't be cleanly round-tripped through the traefik CRD. Omitting
        # them is functionally identical: the plugin defaults to no role gating / no bypass, and for
        # AuthorizationHeader mode it forces CheckOnEveryRequest=true regardless.
        traefik-oidc-auth = merge(
          {
            Provider = {
              Url             = "${data.terraform_remote_state.keycloak.outputs.keycloak_url}/realms/${one(keycloak_openid_client.keycloak_auth_api[*].realm_id)}"
              ClientId        = one(keycloak_openid_client.keycloak_auth_api[*].client_id)
              ClientSecret    = one(keycloak_openid_client.keycloak_auth_api[*].client_secret)
              TokenValidation = var.auth_oidc_api_token_validation

              # ValidateIssuer/ValidateAudience default to true (plugin CreateConfig). ValidIssuer
              # defaults to the discovery document issuer. ValidAudience defaults to ClientId; override
              # with auth_oidc_api_audience when set so cross-client tokens can be validated against a shared aud.
              ValidAudience = var.auth_oidc_api_audience != "" ? var.auth_oidc_api_audience : one(keycloak_openid_client.keycloak_auth_api[*].client_id)
            }

            # Read the bearer token from this header instead of starting an OIDC flow.
            AuthorizationHeader = { Name = "Authorization" }

            # API/offload behaviour: plain 401/403, never a redirect to a login page.
            UnauthenticatedBehavior = "Unauthorized"
            UnauthorizedBehavior    = "Unauthorized"

            Secret  = one(random_password.keycloak_auth_api_plugin_secret[*].result)
            Headers = local.auth_oidc_api_headers
          },
          length(var.auth_oidc_api_required_roles) > 0 ? {
            Authorization = {
              AssertClaims        = local.auth_oidc_api_assert_claims
              CheckOnEveryRequest = true
            }
          } : {},
          var.auth_oidc_api_bypass_rule != "" ? {
            BypassAuthenticationRule = var.auth_oidc_api_bypass_rule
          } : {}
        )
      }
    }
  }
}
