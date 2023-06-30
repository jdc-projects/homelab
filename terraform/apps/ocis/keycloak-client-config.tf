resource "null_resource" "ocis_keycloak_client_name" {
  triggers = {
    client_name = "ocis"
  }
}

resource "keycloak_openid_client" "ocis_client" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = null_resource.ocis_keycloak_client_name.triggers.client_name

  name    = null_resource.ocis_keycloak_client_name.triggers.client_name
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "https://${null_resource.ocis_keycloak_client_name.triggers.client_name}.${var.server_base_domain}/*"
  ]
  web_origins = [
    "https://${null_resource.ocis_keycloak_client_name.triggers.client_name}.${var.server_base_domain}"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = true

  full_scope_allowed = true

  login_theme = "keycloak"
}

resource "keycloak_openid_client_default_scopes" "ocis_client_default_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_client.id

  default_scopes = [
    "acr",
    "email",
    "microprofile-jwt",
    "profile",
    "roles",
    "web-origins",
  ]
}
