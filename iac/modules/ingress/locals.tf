locals {
  is_existing_service  = "" != var.existing_service_name
  is_endpoint_internal = "" == var.external_name

  # Match fragment appended after Host(). Empty when no path is set.
  # PathPrefix (default) keeps the current leading-slash-prepend behavior; PathRegexp
  # emits the caller's regex verbatim (no slash added) — use for regex routes like
  # ingest endpoints (e.g. ^/api/([1-9][0-9]*)/.*).
  path_match_fragment = "" == var.path ? "" : (
    var.path_matcher == "PathRegexp"
    ? " && PathRegexp(`${var.path}`)"
    : " && PathPrefix(`/${var.path}`)"
  )

  # "primary" / "master" are aliases resolved from the keycloak module's remote state (rename-safe).
  # Any other value is treated as a literal realm name and used as-is (the realm must pre-exist).
  keycloak_auth_realm_id = lookup(
    {
      primary = data.terraform_remote_state.keycloak.outputs.primary_realm_id
      master  = data.terraform_remote_state.keycloak.outputs.master_realm_id
    },
    var.keycloak_auth_realm,
    var.keycloak_auth_realm,
  )

  # auth_oidc_managed: true when the module provisions a Keycloak client (default); false when the
  # caller passes a generic OIDC provider via auth_oidc_provider. Gates the Keycloak resources and
  # selects the source of the middleware Provider block inputs.
  auth_oidc_managed = var.auth_oidc_provider == null

  # Guarded access to auth_oidc_provider fields. The == null ternary short-circuits so the attribute
  # access only happens when the var is set (avoids null-attribute errors in the branches below).
  auth_oidc_provider_url           = var.auth_oidc_provider == null ? null : var.auth_oidc_provider.url
  auth_oidc_provider_client_id     = var.auth_oidc_provider == null ? null : var.auth_oidc_provider.client_id
  auth_oidc_provider_client_secret = var.auth_oidc_provider == null ? null : var.auth_oidc_provider.client_secret
  auth_oidc_provider_scopes        = var.auth_oidc_provider == null ? null : var.auth_oidc_provider.scopes

  # Interactive-flow scopes: provider override or the standard trio.
  auth_oidc_interactive_scopes = local.auth_oidc_provider_scopes != null ? local.auth_oidc_provider_scopes : ["openid", "profile", "email"]

  # Effective Provider.ClientSecret per mode. Managed reads the Keycloak client's secret; generic
  # reads the passed provider secret (null when not provided). Null => the field is omitted from the
  # manifest via merge() in each middleware, so no null/empty value reaches the CRD (which would trip
  # the kubernetes_manifest provider's post-apply validation).
  auth_oidc_interactive_client_secret = local.auth_oidc_managed ? one(keycloak_openid_client.keycloak_auth[*].client_secret) : local.auth_oidc_provider_client_secret
  auth_oidc_api_client_secret         = local.auth_oidc_managed ? one(keycloak_openid_client.keycloak_auth_api[*].client_secret) : local.auth_oidc_provider_client_secret

  # Effective ValidAudience for oidc-api: explicit override wins; else managed client id; else
  # generic provider client id. Always a non-null string in practice (client_id is required).
  auth_oidc_api_effective_audience = var.auth_oidc_api_audience != "" ? var.auth_oidc_api_audience : (local.auth_oidc_managed ? one(keycloak_openid_client.keycloak_auth_api[*].client_id) : local.auth_oidc_provider_client_id)

  # Default identity headers injected in oidc-api mode. Templates are evaluated by traefik-oidc-auth
  # over the session context. The {{ with }} guards render an empty value when a claim is absent
  # (e.g. service-account tokens carry no email/name/realm_access) instead of "<no value>" or a
  # malformed mapToJsonArray result. For user tokens all claims are typically present.
  auth_oidc_api_default_headers = [
    { Name = "X-User-Id", Value = "{{ .claims.sub }}" },
    { Name = "X-User-Email", Value = "{{ with .claims.email }}{{ . }}{{ end }}" },
    { Name = "X-Preferred-Username", Value = "{{ with .claims.preferred_username }}{{ . }}{{ end }}" },
    { Name = "X-User-Name", Value = "{{ with .claims.name }}{{ . }}{{ end }}" },
    { Name = "X-User-Roles", Value = "{{ with .claims.realm_access }}{{ mapToJsonArray .roles }}{{ end }}" },
  ]

  auth_oidc_api_headers = concat(
    local.auth_oidc_api_default_headers,
    var.auth_oidc_api_pass_access_token ? [{ Name = "X-Access-Token", Value = "{{ .accessToken }}" }] : [],
    var.auth_oidc_api_extra_headers,
  )

  # AssertClaims entry for required realm roles. The plugin evaluates Name as JSONPath ("$.<Name>"),
  # so "realm_access.roles" resolves into the nested roles array. Empty when no roles required.
  auth_oidc_api_assert_claims = length(var.auth_oidc_api_required_roles) > 0 ? [{
    Name  = "realm_access.roles"
    AnyOf = var.auth_oidc_api_required_roles
  }] : []

  middlewares = concat(
    var.do_enable_cloudflare_middleware ? [{
      name      = "cloudflare"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }] : [],
    var.do_enable_geoblock ? [{
      name      = "geoblock"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }] : [],
    var.do_enable_crowdsec_bouncer && var.do_enable_crowdsec_bouncer_appsec ? [{
      name      = "crowdsec-bouncer"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
      }] : var.do_enable_crowdsec_bouncer && !var.do_enable_crowdsec_bouncer_appsec ? [{
      name      = "crowdsec-bouncer-without-appsec"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }] : [],
    var.auth_mode == "api-key" ? [{
      name      = one(kubernetes_manifest.api_key_auth_plugin_middleware[*].manifest.metadata.name)
      namespace = var.namespace
    }] : [],
    var.auth_mode == "oidc-interactive" ? [{
      name      = one(kubernetes_manifest.keycloak_auth_plugin_middleware[*].manifest.metadata.name)
      namespace = var.namespace
    }] : [],
    var.auth_mode == "oidc-api" ? [{
      name      = one(kubernetes_manifest.keycloak_auth_api_plugin_middleware[*].manifest.metadata.name)
      namespace = var.namespace
    }] : [],
    var.extra_middlewares
  )
}
