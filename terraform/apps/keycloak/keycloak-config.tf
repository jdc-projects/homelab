resource "keycloak_realm" "lldap_realm" {
  realm   = "my-realm"
  enabled = true
}

resource "keycloak_ldap_user_federation" "lldap_user_federation" {
  name      = "openldap"
  realm_id  = keycloak_realm.lldap_realm.id
  enabled   = true
  vendor    = "OTHER"
  edit_mode = "READ_ONLY"

  username_ldap_attribute = "uid"
  rdn_ldap_attribute      = "uid"
  uuid_ldap_attribute     = "uid"
  user_object_classes = [
    "person"
  ]
  connection_url  = "ldaps://idm.${var.server_base_domain}"
  users_dn        = "ou=people,dc=idm,dc=${var.server_base_domain}"
  bind_dn         = "uid=admin,ou=peopledc=idm,dc=${var.server_base_domain}"
  bind_credential = var.lldap_admin_password

  pagination = false
}

resource "keycloak_ldap_role_mapper" "lldap_role_mapper" {
  realm_id                = keycloak_realm.lldap_realm.id
  ldap_user_federation_id = keycloak_ldap_user_federation.lldap_user_federation.id
  name                    = "role-mapper"

  ldap_roles_dn            = "ou=group,dc=idm,dc=${var.server_base_domain}"
  role_name_ldap_attribute = "cn"
  role_object_classes = [
    "groupOfUniqueNames"
  ]
  membership_ldap_attribute      = "member"
  membership_user_ldap_attribute = "cn"

  mode = "READ_ONLY"
}
