resource "keycloak_realm" "lldap_realm" {
  realm   = "my-realm"
  enabled = true

  registration_email_as_username = false
  login_with_email_allowed       = false
  duplicate_emails_allowed       = true
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
  bind_dn         = "uid=admin,ou=people,dc=idm,dc=${var.server_base_domain}"
  bind_credential = var.lldap_admin_password

  pagination                      = false
  use_password_modify_extended_op = true
}

resource "keycloak_ldap_group_mapper" "lldap_group_mapper" {
  realm_id                = keycloak_realm.lldap_realm.id
  ldap_user_federation_id = keycloak_ldap_user_federation.lldap_user_federation.id
  name                    = "group-mapper"

  ldap_groups_dn            = "ou=groups,dc=idm,dc=${var.server_base_domain}"
  group_name_ldap_attribute = "cn"
  group_object_classes = [
    "groupOfUniqueNames"
  ]
  membership_ldap_attribute      = "member"
  membership_user_ldap_attribute = "cn"

  mode = "READ_ONLY"
}
