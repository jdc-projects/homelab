data "keycloak_group" "system_admins" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  name     = "system_admins"
}

resource "keycloak_role" "oauth2_proxy_admin" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id   = keycloak_openid_client.oauth2_proxy.id
  name        = "oauth2ProxyAdmin"
  description = "Oauth2 Proxy Admin"
}

resource "keycloak_group_roles" "oauth2_proxy_admin" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  group_id = data.keycloak_group.system_admins.id

  role_ids = [
    keycloak_role.oauth2_proxy_admin.id
  ]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_claim_mapper" {
  realm_id                    = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id                   = keycloak_openid_client.oauth2_proxy.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = keycloak_openid_client.oauth2_proxy.client_id

  multivalued = "true"

  add_to_id_token     = "true"
  add_to_access_token = "true"
  add_to_userinfo     = "true"
}
