data "keycloak_group" "system_admins" {
  realm_id = keycloak_realm.server_base_domain.id
  name     = "system_admins"
}

data "keycloak_role" "admin" {
  realm_id = keycloak_realm.server_base_domain.id
  name     = "admin"
}

resource "keycloak_group_roles" "system_admins_admin" {
  realm_id = keycloak_realm.server_base_domain.id
  group_id = data.keycloak_group.system_admins.id

  role_ids = [
    data.keycloak_role.admin
  ]
}
