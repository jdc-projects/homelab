data "keycloak_group" "system_admins" {
  for_each = tomap({
    master = tomap({
      realm_id = data.keycloak_realm.master.id
    })
    primary = tomap({
      realm_id = keycloak_realm.primary.id
    })
  })
  realm_id = each.value.realm_id
  name     = "system_admins"

  depends_on = [keycloak_ldap_group_mapper.openldap]
}

data "keycloak_role" "admin" {
  realm_id = data.keycloak_realm.master.id
  name     = "admin"
}

resource "keycloak_group_roles" "system_admins_admin" {
  realm_id = data.keycloak_realm.master.id
  group_id = data.keycloak_group.system_admins["master"].id

  role_ids = [
    data.keycloak_role.admin.id
  ]

  exhaustive = false
}
