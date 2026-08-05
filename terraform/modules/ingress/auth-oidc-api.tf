# API/offload auth mode (oidc-api): validates a bearer token from the Authorization header against
# the OIDC provider (default: stateless JWKS signature check on the access token), injects identity
# claims as upstream headers, and returns 401/403 on failure (no redirect, no login page). Mimics
# AWS API Gateway / Azure APIM JWT validation.
#
# Supports two provider sources, selected by auth_oidc_provider:
#   - null (default, "managed"): the module provisions a Keycloak client (keycloak_openid_client)
#     and an audience protocol mapper below. ValidAudience defaults to that client's id.
#   - set ("generic"): the module creates no Keycloak resources; Provider Url/ClientId/ClientSecret
#     come straight from auth_oidc_provider. The client must be provisioned out-of-band in your IdP.
#
# TokenValidation defaults to AccessToken (local JWKS). Introspection mode calls the provider's
# introspection endpoint per request - it catches revoked tokens but is slower and needs the client
# secret. For the managed Keycloak path, note the audience caveat: Keycloak 26 requires the
# introspecting client to be in the access token's `aud` claim, so set auth_oidc_api_audience and
# ensure issuing clients carry it (via their own audience mappers) when using Introspection.

resource "random_password" "keycloak_auth_api_client_secret" {
  count = var.auth_mode == "oidc-api" && local.auth_oidc_managed ? 1 : 0

  length  = 50
  numeric = true
  special = false
  upper   = true
}

# The plugin Secret (32-char, encrypts state) is provider-independent - created for both managed and
# generic paths.
resource "random_password" "keycloak_auth_api_plugin_secret" {
  count = var.auth_mode == "oidc-api" ? 1 : 0

  length  = 32
  special = false
}

resource "keycloak_openid_client" "keycloak_auth_api" {
  count = var.auth_mode == "oidc-api" && local.auth_oidc_managed ? 1 : 0

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
# default) and is overridden by auth_oidc_api_audience for cross-client validation. Managed path
# only - generic providers must configure their own client's audience out-of-band. Note: this only
# shapes tokens minted by THIS client - tokens minted by OTHER clients need their own mappers.
resource "keycloak_openid_audience_protocol_mapper" "api_audience" {
  count = var.auth_mode == "oidc-api" && local.auth_oidc_managed ? 1 : 0

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
            # Provider inputs switch on managed vs generic. ClientSecret is overlaid via a nested
            # merge() so it's omitted when null (generic + JWKS-only, no secret needed).
            Provider = merge(
              {
                Url             = local.auth_oidc_managed ? "${data.terraform_remote_state.keycloak.outputs.keycloak_url}/realms/${one(keycloak_openid_client.keycloak_auth_api[*].realm_id)}" : local.auth_oidc_provider_url
                ClientId        = local.auth_oidc_managed ? one(keycloak_openid_client.keycloak_auth_api[*].client_id) : local.auth_oidc_provider_client_id
                TokenValidation = var.auth_oidc_api_token_validation

                # ValidateIssuer/ValidateAudience default to true (plugin CreateConfig). ValidIssuer
                # defaults to the discovery document issuer. ValidAudience = explicit override, else
                # managed client id, else generic provider client id (see local.auth_oidc_api_effective_audience).
                ValidAudience = local.auth_oidc_api_effective_audience
              },
              local.auth_oidc_api_client_secret != null ? {
                ClientSecret = local.auth_oidc_api_client_secret
              } : {}
            )

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
