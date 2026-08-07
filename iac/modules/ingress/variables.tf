variable "name" {
  type        = string
  description = "Name / prefix used for resource names."
}

variable "namespace" {
  type        = string
  description = "Namespace to put resources in. Should match the namespace of the endpoint / application."
}

variable "domain" {
  type        = string
  description = "Domain for the URL."
}

variable "path" {
  type        = string
  description = "Path for the URL ($domain/$path)"
  default     = ""
}

variable "path_matcher" {
  type        = string
  description = "Traefik matcher applied to 'path'. \"PathPrefix\" (default) = literal prefix match; an automatic leading slash is prepended to 'path' (current behavior). \"PathRegexp\" = treats 'path' as a Traefik regular expression and emits it verbatim (no slash added) — use for routes that must match a regex, e.g. an ingest endpoint matching '^/api/([1-9][0-9]*)/.*'."
  default     = "PathPrefix"

  validation {
    condition     = contains(["PathPrefix", "PathRegexp"], var.path_matcher)
    error_message = "path_matcher must be one of: PathPrefix, PathRegexp."
  }
}

variable "target_port" {
  type        = number
  description = "Port on the application / endpoint that the service should connect to. If using an existing service, this should be the port on the service."
}

variable "selector" {
  type        = map(string)
  description = "Selector that the service should use. Not used if external."
  default     = null

  validation {
    condition = !(
      (null == var.selector && "" == var.external_name && "" == var.existing_service_name) || # if they're all unset
      (null != var.selector && "" != var.external_name) ||                                    # if two are set v1
      (null != var.selector && "" != var.existing_service_name) ||                            # if two are set v2
      ("" != var.external_name && "" != var.existing_service_name)                            # if two are set v3
    )
    error_message = "Exactly one of 'selector', 'external_name', 'existing_service_name' must be set."
  }
}

variable "external_name" {
  type        = string
  description = "External domain or IP for to expose. Not used if internal."
  default     = ""
}

variable "existing_service_name" {
  type        = string
  description = "Name of existing service to be used. Must be pointing to an internal endpoint."
  default     = ""
}

variable "existing_service_namespace" {
  type        = string
  description = "Namespace of existing service to be used. Must be pointing to an internal endpoint."
  default     = ""

  validation {
    condition     = ("" == var.existing_service_namespace && "" == var.existing_service_name) || ("" != var.existing_service_namespace && "" != var.existing_service_name)
    error_message = "If 'existing_service_name' is set, 'existing_service_namespace' must also be set."
  }
}

variable "priority" {
  type        = number
  description = "Priority for the ingress. Larger number = higher priority. 0 uses built-in priority management."
  default     = 0
}

variable "is_scheme_http" {
  type        = string
  description = "True if scheme for external endpoint is http. False if HTTPS. Not used if internal."
  default     = true
}

variable "do_enable_cloudflare_middleware" {
  type        = bool
  description = "True to enable Cloudflare middleware."
  default     = true
}

variable "do_enable_geoblock" {
  type        = bool
  description = "True to enable Geoblock middleware."
  default     = true
}

variable "do_enable_crowdsec_bouncer" {
  type        = bool
  description = "True to enable Crowdsec Bouncer middleware."
  default     = true
}

variable "do_enable_crowdsec_bouncer_appsec" {
  type        = bool
  description = "True to enable Crowdsec Bouncer appsec component."
  default     = true
}

variable "auth_mode" {
  type        = string
  description = "Authentication mode. \"none\" = no auth middleware. \"oidc-interactive\" = full OIDC flow (login page, redirects, session cookie) via the traefik-oidc-auth plugin. \"oidc-api\" = OIDC offload (bearer-token validation + claim-derived headers injected upstream, 401 on failure, no redirect) - mimics AWS API Gateway / Azure APIM JWT validation. \"api-key\" = static API key validation via the api-key-auth plugin (X-API-KEY header or Authorization: Bearer); the generated key is exposed in the api_key output."
  default     = "none"

  validation {
    condition     = contains(["none", "oidc-interactive", "oidc-api", "api-key"], var.auth_mode)
    error_message = "auth_mode must be one of: none, oidc-interactive, oidc-api, api-key."
  }
}

variable "keycloak_auth_realm" {
  type        = string
  description = "Keycloak realm for the managed auth client. \"primary\" and \"master\" are aliases resolved from the keycloak module's remote state (rename-safe). Any other value is treated as a literal realm name and used as-is (the realm must already exist in Keycloak - the module does not create it). Non-alias values trigger the non-blocking keycloak_auth_realm_known check; see silenced_checks. Only relevant when auth_mode is an oidc mode AND auth_oidc_provider is null (managed)."
  default     = "primary"
}

variable "auth_oidc_provider" {
  type = object({
    url           = string
    client_id     = string
    client_secret = optional(string)
    scopes        = optional(list(string))
  })
  default     = null
  description = "Generic OIDC provider connection details (url = discovery/issuer URL). When set, the module uses this provider directly and creates NO Keycloak client - the client must be provisioned out-of-band in your IdP. When null (default), the module provisions and uses a managed Keycloak client. Only applies when auth_mode is oidc-interactive or oidc-api. client_secret is optional (omit for PKCE-only/JWKS-only; required for Introspection); scopes override the interactive-flow default."

  validation {
    condition     = var.auth_oidc_provider == null || contains(["oidc-interactive", "oidc-api"], var.auth_mode)
    error_message = "auth_oidc_provider can only be set when auth_mode is oidc-interactive or oidc-api."
  }
}

variable "auth_oidc_api_token_validation" {
  type        = string
  description = "Token validation mode for oidc-api auth. \"AccessToken\" = stateless local JWKS signature validation (default, mimics AWS API Gateway JWT authorizer). \"Introspection\" = call Keycloak's introspection endpoint per request (catches revoked tokens, slower, needs the client secret at the gateway)."
  default     = "AccessToken"

  validation {
    condition     = contains(["AccessToken", "Introspection"], var.auth_oidc_api_token_validation)
    error_message = "auth_oidc_api_token_validation must be one of: AccessToken, Introspection."
  }
}

variable "auth_oidc_api_audience" {
  type        = string
  description = "Expected audience (aud claim) for api auth. When set, the middleware validates the access token's aud contains this value AND a Keycloak audience protocol mapper is added to the client so tokens it mints carry it. When empty, audience validation falls back to the client id. For cross-client token validation (tokens minted by other clients), set this to a shared audience and configure matching mappers on all participating Keycloak clients."
  default     = ""
}

variable "auth_oidc_api_required_roles" {
  type        = list(string)
  description = "Keycloak realm roles (from the realm_access.roles claim) required to authorize a request in api mode. The gateway 403s before reaching the backend if none match (AssertClaims anyOf, evaluated by the plugin as JSONPath \"$.realm_access.roles\"). Empty = authentication only (no role gating); backends do their own authorization. Assumes Keycloak access tokens, which carry realm_access.roles by default."
  default     = []
}

variable "auth_oidc_api_pass_access_token" {
  type        = bool
  description = "True to forward the raw access token to the backend as X-Access-Token (for backends that need to perform their own fine-grained authorization or audit). The identity headers (X-User-Id etc.) are always injected regardless."
  default     = true
}

variable "auth_oidc_api_extra_headers" {
  type = list(object({
    Name  = string
    Value = string
  }))
  description = "Additional headers to inject in api mode, appended after the defaults. PascalCase keys mirror the plugin's Header schema. Each Value is a Go template evaluated over the plugin context (e.g. {{ .claims.sub }}, {{ .claims.email }}, {{ .accessToken }}, {{ .idToken }}). See the traefik-oidc-auth Headers config. Note: Kubernetes CRD config does NOT require the backtick-escaping that YAML file config does."
  default     = []
}

variable "auth_oidc_api_bypass_rule" {
  type        = string
  description = "A traefik-oidc-auth predicate expression that, when matched, bypasses authentication for the request (e.g. public API routes). Empty = no bypass (all requests require a valid token). See the plugin's BypassAuthenticationRule docs."
  default     = ""
}

variable "silenced_checks" {
  type        = list(string)
  description = <<-EOT
    Names of check blocks in this module to silence (they are non-blocking warnings by design).
    Add a check name here only AFTER confirming its assertion is intentionally satisfied
    (e.g. a non-alias realm you've verified exists in Keycloak).
    Do NOT silence a check if you have made any change that affects what it validates -
    re-verify first and leave it unsilenced until confirmed.
    Typoing a check name here is fail-safe: the warning will still fire.
    Current check names: keycloak_auth_realm_known.
  EOT
  default     = []
}

variable "extra_middlewares" {
  type        = list(map(string))
  description = "Extra middlewares to use."
  default     = []
}

variable "kubeconfig_path" {
  type        = string
  default     = "../cluster.yml"
  description = "Path to the kubeconfig used to read remote state from the kubernetes backend. Resolved relative to the directory tofu runs in. In-repo callers use the default; external consumers override with their own path."
}
