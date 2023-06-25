# resource "keycloak_ldap_role_mapper" "ocis_admin_role_mapper" {
#   realm_id                = keycloak_realm.realm.id
#   ldap_user_federation_id = keycloak_ldap_user_federation.ldap_user_federation.id
#   name                    = "role-mapper"

#   ldap_roles_dn                 = "dc=example,dc=org"
#   role_name_ldap_attribute      = "cn"
#   role_object_classes           = [
#     "groupOfNames"
#   ]
#   membership_attribute_type      = "DN"
#   membership_ldap_attribute      = "member"
#   membership_user_ldap_attribute = "cn"
#   user_roles_retrieve_strategy   = "GET_ROLES_FROM_USER_MEMBEROF_ATTRIBUTE"
#   memberof_ldap_attribute        = "memberOf"
# }
