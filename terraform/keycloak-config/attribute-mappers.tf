locals {
  attribute_mapper_settings = tomap({
    creation_date = tomap({
      mapper_name        = "creation date"
      keycloak_attribute = "createTimestamp"
      ldap_attribute     = "createTimestamp"
    })
    email = tomap({
      mapper_name        = "email"
      keycloak_attribute = "email"
      ldap_attribute     = "mail"
    })
    first_name = tomap({
      mapper_name        = "first name"
      keycloak_attribute = "firstName"
      ldap_attribute     = "givenName"
    })
    last_name = tomap({
      mapper_name        = "last name"
      keycloak_attribute = "lastName"
      ldap_attribute     = "sn"
    })
    modify_date = tomap({
      mapper_name        = "modify date"
      keycloak_attribute = "modifyTimestamp"
      ldap_attribute     = "modifyTimestamp"
    })
    username = tomap({
      mapper_name        = "username"
      keycloak_attribute = "username"
      ldap_attribute     = "uid"
    })
  })
}

resource "keycloak_ldap_user_attribute_mapper" "master" {
  for_each = local.attribute_mapper_settings

  realm_id                = data.keycloak_realm.master.id
  ldap_user_federation_id = keycloak_ldap_user_federation.openldap["master"].id
  name                    = each.value.mapper_name

  user_model_attribute = each.value.keycloak_attribute
  ldap_attribute       = each.value.ldap_attribute

  read_only                   = "true"
  always_read_value_from_ldap = "true"
}

resource "keycloak_ldap_user_attribute_mapper" "server_base_domain" {
  for_each = local.attribute_mapper_settings

  realm_id                = keycloak_realm.server_base_domain.id
  ldap_user_federation_id = keycloak_ldap_user_federation.openldap["server_base_domain"].id
  name                    = each.value.mapper_name

  user_model_attribute = each.value.keycloak_attribute
  ldap_attribute       = each.value.ldap_attribute

  read_only                   = "true"
  always_read_value_from_ldap = "true"
}
