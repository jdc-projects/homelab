resource "keycloak_role" "grafana_admin" {
  realm_id    = keycloak_realm.primary.id
  client_id   = keycloak_openid_client.grafana.id
  name        = data.terraform_remote_state.prometheus_operator.outputs.grafana_oauth_admin_role_name
  description = "Grafana Admin"
}

resource "keycloak_group_roles" "grafana_admin" {
  realm_id = keycloak_realm.primary.id
  group_id = data.keycloak_group.system_admins["primary"].id

  role_ids = [
    keycloak_role.grafana_admin.id
  ]

  exhaustive = false
}

resource "keycloak_openid_user_client_role_protocol_mapper" "grafana_claim_mapper" {
  realm_id                    = keycloak_realm.primary.id
  client_id                   = keycloak_openid_client.grafana.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = keycloak_openid_client.grafana.client_id

  multivalued = "true"

  add_to_id_token     = "true"
  add_to_access_token = "true"
  add_to_userinfo     = "true"
}
