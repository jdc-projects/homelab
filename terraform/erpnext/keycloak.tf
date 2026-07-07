resource "keycloak_openid_client" "erpnext" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "erpnext"

  name    = "erpnext"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${local.erpnext_domain}/*",
  ]
  web_origins = [
    "https://${local.erpnext_domain}",
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}

resource "keycloak_openid_group_membership_protocol_mapper" "erpnext_groups" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = keycloak_openid_client.erpnext.id
  name      = "groups"

  claim_name          = "groups"
  full_path           = false
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}
