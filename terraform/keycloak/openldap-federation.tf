resource "keycloak_ldap_user_federation" "openldap" {
  for_each = tomap({
    primary = tomap({
      id = keycloak_realm.primary.id
    })
    master = tomap({
      id = data.keycloak_realm.master.id
    })
  })

  name      = "openldap"
  realm_id  = each.value.id
  enabled   = true
  edit_mode = "READ_ONLY"

  username_ldap_attribute = "uid"
  rdn_ldap_attribute      = "uid"
  uuid_ldap_attribute     = "uid"
  user_object_classes = [
    "inetOrgPerson"
  ]
  connection_url  = "ldaps://idm.${var.server_base_domain}"
  users_dn        = "ou=people,dc=idm,dc=homelab"
  bind_dn         = "uid=${data.terraform_remote_state.openldap.outputs.admin_username},ou=people,dc=idm,dc=homelab"
  bind_credential = data.terraform_remote_state.openldap.outputs.admin_password

  custom_user_search_filter = each.value.id == data.keycloak_realm.master.id ? "(&(objectClass=inetOrgPerson)(memberOf=cn=system_admins,ou=groups,dc=idm,dc=homelab))" : ""

  use_password_modify_extended_op = false

  trust_email = true

  pagination = false

  full_sync_period = 60

  delete_default_mappers = "true"
}

resource "keycloak_ldap_group_mapper" "openldap" {
  for_each = tomap({
    primary = tomap({
      realm_id                    = keycloak_realm.primary.id
      ldap_federation_id          = keycloak_ldap_user_federation.openldap["primary"].id
      ldap_federation_sync_period = keycloak_ldap_user_federation.openldap["primary"].full_sync_period
    })
    master = tomap({
      realm_id                    = data.keycloak_realm.master.id
      ldap_federation_id          = keycloak_ldap_user_federation.openldap["master"].id
      ldap_federation_sync_period = keycloak_ldap_user_federation.openldap["master"].full_sync_period
    })
  })

  realm_id                = each.value.realm_id
  ldap_user_federation_id = each.value.ldap_federation_id
  name                    = "group mapper"

  ldap_groups_dn            = "ou=groups,dc=idm,dc=homelab"
  group_name_ldap_attribute = "cn"
  group_object_classes = [
    "groupOfNames"
  ]
  membership_ldap_attribute      = "member"
  membership_user_ldap_attribute = "cn"

  mode = "READ_ONLY"

  drop_non_existing_groups_during_sync = true

  provisioner "local-exec" {
    # wait for a sync so that groups have a change to sync
    command = "sleep ${each.value.ldap_federation_sync_period}"
  }
}
