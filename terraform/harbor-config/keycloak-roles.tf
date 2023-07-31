data "keycloak_group" "system_admins" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  name     = "system_admins"
}

resource "keycloak_role" "system_admin" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id   = keycloak_openid_client.harbor.id
  name        = "systemAdmin"
  description = "System Admin"
}

resource "keycloak_group_roles" "system_admin" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  group_id = data.keycloak_group.system_admins.id

  role_ids = [
    keycloak_role.system_admin.id
  ]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_claim_mapper" {
  realm_id                    = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id                   = keycloak_openid_client.harbor.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = keycloak_openid_client.harbor.client_id

  multivalued = "true"

  add_to_id_token     = "true"
  add_to_access_token = "true"
  add_to_userinfo     = "true"
}
