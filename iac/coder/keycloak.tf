resource "keycloak_openid_client" "coder" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "coder"

  name    = "Coder"
  enabled = true

  access_type = "CONFIDENTIAL"
  # Coder's OIDC callback path (differs from the usual /oidc/callback).
  valid_redirect_uris = [
    "https://${local.coder_domain}/api/v2/users/oidc/callback",
  ]
  web_origins = [
    "https://${local.coder_domain}",
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false

  full_scope_allowed = false

  # Per-client access-token lifespan (30m), overriding the realm default (5m).
  # coderd refreshes the workspace owner's OIDC token at every build and bakes
  # it into the build's provisioning metadata (surfaced to templates as
  # coder_workspace_owner.me.oidc_access_token — e.g. the vault-jwt module
  # passes it to Vault). The token is minted at provision time but consumed at
  # agent start: seconds later for pods, ~2-3min after a VM boot. The realm's
  # 5m default is too tight for that window; 30m covers it comfortably.
  access_token_lifespan = "1800"

  login_theme = "keycloak"
}
