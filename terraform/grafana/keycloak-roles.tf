data "keycloak_group" "system_admins" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.primary_realm_id
  name     = "system_admins"
}

resource "keycloak_role" "grafana_admin" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.primary_realm_id
  client_id   = keycloak_openid_client.grafana.id
  name        = "grafanaAdmin"
  description = "Grafana Admin"
}

resource "keycloak_group_roles" "grafana_admin" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.primary_realm_id
  group_id = data.keycloak_group.system_admins.id

  role_ids = [
    keycloak_role.grafana_admin.id
  ]

  exhaustive = false
}

resource "keycloak_openid_user_client_role_protocol_mapper" "grafana_claim_mapper" {
  realm_id                    = data.terraform_remote_state.keycloak_config.outputs.primary_realm_id
  client_id                   = keycloak_openid_client.grafana.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = keycloak_openid_client.grafana.client_id

  multivalued = "true"

  add_to_id_token     = "true"
  add_to_access_token = "true"
  add_to_userinfo     = "true"
}
