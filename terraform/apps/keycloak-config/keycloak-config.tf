resource "keycloak_realm" "jack_chapman_co_uk_realm" {
  realm   = "jack-chapman.co.uk"
  enabled = true

  registration_email_as_username = false
  login_with_email_allowed       = false
  duplicate_emails_allowed       = true
}

resource "keycloak_ldap_user_federation" "openldap_user_federation" {
  name      = "openldap"
  realm_id  = keycloak_realm.jack_chapman_co_uk_realm.id
  enabled   = true
  edit_mode = "WRITABLE"

  username_ldap_attribute = "uid"
  rdn_ldap_attribute      = "uid"
  uuid_ldap_attribute     = "uid"
  user_object_classes = [
    "inetOrgPerson"
  ]
  connection_url  = "ldaps://idm.${var.server_base_domain}"
  users_dn        = "ou=people,dc=idm,dc=${var.server_base_domain}"
  bind_dn         = "uid=${data.terraform_remote_state.openldap.outputs.openldap_username},ou=people,dc=idm,dc=${var.server_base_domain}"
  bind_credential = data.terraform_remote_state.openldap.outputs.openldap_password

  use_password_modify_extended_op = false

  pagination = false

  full_sync_period = 60
}

resource "keycloak_ldap_group_mapper" "openldap_group_mapper" {
  realm_id                = keycloak_realm.jack_chapman_co_uk_realm.id
  ldap_user_federation_id = keycloak_ldap_user_federation.openldap_user_federation.id
  name                    = "openldap-group-mapper"

  ldap_groups_dn            = "ou=groups,dc=idm,dc=${var.server_base_domain}"
  group_name_ldap_attribute = "cn"
  group_object_classes = [
    "groupOfUniqueNames"
  ]
  membership_ldap_attribute      = "memberOf"
  membership_user_ldap_attribute = "cn"

  mode = "READ_ONLY"

  drop_non_existing_groups_during_sync = true

  provisioner "local-exec" {
    # wait for a sync so that groups have a change to sync
    command = "sleep ${keycloak_ldap_user_federation.openldap_user_federation.full_sync_period}"
  }
}

data "keycloak_openid_client_scope" "keycloak_roles_scope" {
  realm_id = keycloak_realm.jack_chapman_co_uk_realm.id
  name     = "roles"
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "user_realm_role_mapper" {
  realm_id = keycloak_realm.jack_chapman_co_uk_realm.id
  name     = "user-info-role-mapper"

  client_scope_id = data.keycloak_openid_client_scope.keycloak_roles_scope.id

  claim_name       = "roles"
  claim_value_type = "String"

  multivalued = true

  add_to_id_token     = false
  add_to_access_token = false
  add_to_userinfo     = true
}
