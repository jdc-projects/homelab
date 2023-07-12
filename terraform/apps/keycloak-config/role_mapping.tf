data "keycloak_group" "system_admins" {
  realm_id = data.keycloak_realm.master.id
  name     = "system_admins"
}

data "keycloak_role" "admin" {
  realm_id = data.keycloak_realm.master.id
  name     = "admin"
}

resource "keycloak_group_roles" "system_admins_admin" {
  realm_id = data.keycloak_realm.master.id
  group_id = data.keycloak_group.system_admins.id

  role_ids = [
    data.keycloak_role.admin
  ]
}
