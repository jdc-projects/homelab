# Shared auth elements for the ingress module.
#
# auth_mode selects how (if at all) requests are authenticated before reaching the backend:
#   - "none":            no auth middleware.
#   - "oidc-interactive": full OIDC flow (login page, redirects, session cookie). See keycloak-auth-interactive.tf.
#   - "oidc-api":         OIDC offload (bearer-token validation + claim-derived headers injected upstream,
#                        401 on failure, no redirect). See keycloak-auth-api.tf. Mimics AWS API Gateway /
#                        Azure APIM JWT validation.
#   - "api-key":         static API key validation (X-API-KEY header or Authorization: Bearer). See api-key-auth.tf.
#
# The OIDC modes share keycloak_auth_realm (resolved to a realm id in locals.tf) and the soft check below.

# Soft (non-blocking) check: warns at plan time when keycloak_auth_realm is not a known alias, so a
# typo'd or non-existent realm is a conscious choice rather than a silent failure. Non-alias values
# are still used as literal realm names (see local.keycloak_auth_realm_id) - a wrong name will also
# fail loudly at apply (Keycloak rejects the client creation / discovery 404s). Silence by adding
# "keycloak_auth_realm_known" to var.silenced_checks. Do NOT silence after any change that affects
# what this check validates (realm/client config) until re-verified; see silenced_checks description.
check "keycloak_auth_realm_known" {
  assert {
    condition = anytrue([
      contains(var.silenced_checks, "keycloak_auth_realm_known"),
      var.auth_mode == "none",
      contains(["primary", "master"], var.keycloak_auth_realm),
    ])
    error_message = "keycloak_auth_realm='${var.keycloak_auth_realm}' is not a known alias (primary/master); treating it as a literal realm name. Ensure that realm exists in Keycloak. If verified intentional, add 'keycloak_auth_realm_known' to silenced_checks."
  }
}
