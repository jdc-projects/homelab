resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

# OpenBao's OIDC client for human logins (UI + CLI authorization-code flow).
resource "keycloak_openid_client" "openbao" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "openbao"

  name    = "openbao"
  enabled = true

  access_type               = "CONFIDENTIAL"
  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false

  valid_redirect_uris = local.oidc_redirect_uris

  full_scope_allowed = false

  login_theme = "keycloak"
}

# Emit the user's group memberships as the `groups` claim; the OpenBao admin
# role bound_claims on it (system_admins -> openbao-admin policy).
resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = keycloak_openid_client.openbao.id
  name      = "groups"

  claim_name          = "groups"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}
