resource "kubernetes_config_map" "openldap_custom_ldifs" {
  metadata {
    name      = "openldap-custom-ldifs"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    "00-base.ldif"   = <<-EOF
      ## Build the root node.
      dn: dc=idm,dc=homelab
      objectClass: dcObject
      objectClass: organizationalUnit
      dc: idm
      ou: idm

      ## Build the people ou.
      dn: ou=people,dc=idm,dc=homelab
      objectClass: organizationalUnit
      ou: people

      ## Build the groups ou.
      dn: ou=groups,dc=idm,dc=homelab
      objectClass: organizationalUnit
      ou: groups
    EOF
    "70-users.ldif"  = <<-EOF
      # create admin user
      dn: uid=${random_password.openldap_admin_username.result},ou=people,dc=idm,dc=homelab
      objectClass: person
      objectClass: inetOrgPerson
      objectClass: posixAccount
      uid: ${random_password.openldap_admin_username.result}
      cn: admin
      givenName: System
      sn: Admin
      displayName: System Admin
      mail: admin@${var.server_base_domain}
      uidNumber: 5000
      gidNumber: 5000
      homeDirectory: /home/${random_password.openldap_admin_username.result}
      userPassword: ${random_password.openldap_admin_password.result}

      # create app test admin user
      dn: uid=${random_password.openldap_test_admin_username.result},ou=people,dc=idm,dc=homelab
      objectClass: person
      objectClass: inetOrgPerson
      objectClass: posixAccount
      uid: ${random_password.openldap_test_admin_username.result}
      cn: test-admin
      givenName: Test
      sn: Admin
      displayName: Test Admin
      mail: testadmin@${var.server_base_domain}
      uidNumber: 6000
      gidNumber: 6000
      homeDirectory: /home/${random_password.openldap_test_admin_username.result}
      userPassword: ${random_password.openldap_test_admin_password.result}

      # create app test user
      dn: uid=${random_password.openldap_test_user_username.result},ou=people,dc=idm,dc=homelab
      objectClass: person
      objectClass: inetOrgPerson
      objectClass: posixAccount
      uid: ${random_password.openldap_test_user_username.result}
      cn: test-user
      givenName: Test
      sn: User
      displayName: Test User
      mail: testuser@${var.server_base_domain}
      uidNumber: 6100
      gidNumber: 6100
      homeDirectory: /home/${random_password.openldap_test_user_username.result}
      userPassword: ${random_password.openldap_test_user_password.result}

      # create app test guest user
      dn: uid=${random_password.openldap_test_guest_username.result},ou=people,dc=idm,dc=homelab
      objectClass: person
      objectClass: inetOrgPerson
      objectClass: posixAccount
      uid: ${random_password.openldap_test_guest_username.result}
      cn: test-guest
      givenName: Test
      sn: Guest
      displayName: Test Guest
      mail: testguest@${var.server_base_domain}
      uidNumber: 6200
      gidNumber: 6200
      homeDirectory: /home/${random_password.openldap_test_guest_username.result}
      userPassword: ${random_password.openldap_test_guest_password.result}

      # create app test disabled user
      dn: uid=${random_password.openldap_test_disabled_username.result},ou=people,dc=idm,dc=homelab
      objectClass: person
      objectClass: inetOrgPerson
      objectClass: posixAccount
      uid: ${random_password.openldap_test_disabled_username.result}
      cn: test-disabled
      givenName: Test
      sn: Disabled
      displayName: Test Disabled
      mail: testdisabled@${var.server_base_domain}
      uidNumber: 6300
      gidNumber: 6300
      homeDirectory: /home/${random_password.openldap_test_disabled_username.result}
      userPassword: ${random_password.openldap_test_disabled_password.result}
    EOF
    "80-groups.ldif" = <<-EOF
      # create system admins group
      dn: cn=system_admins,ou=groups,dc=idm,dc=homelab
      objectClass: groupOfNames
      objectClass: posixGroup
      cn: system_admins
      gidNumber: 5000
      member: uid=${random_password.openldap_admin_username.result},ou=people,dc=idm,dc=homelab

      # create app admins group
      dn: cn=app_admins,ou=groups,dc=idm,dc=homelab
      objectClass: groupOfNames
      objectClass: posixGroup
      cn: app_admins
      gidNumber: 6000
      member: uid=${random_password.openldap_test_admin_username.result},ou=people,dc=idm,dc=homelab

      # create app users group
      dn: cn=app_users,ou=groups,dc=idm,dc=homelab
      objectClass: groupOfNames
      objectClass: posixGroup
      cn: app_users
      gidNumber: 6100
      member: uid=${random_password.openldap_test_user_username.result},ou=people,dc=idm,dc=homelab

      # create app guests group
      dn: cn=app_guests,ou=groups,dc=idm,dc=homelab
      objectClass: groupOfNames
      objectClass: posixGroup
      cn: app_guests
      gidNumber: 6200
      member: uid=${random_password.openldap_test_guest_username.result},ou=people,dc=idm,dc=homelab

      # create app disabled group
      dn: cn=app_disabled,ou=groups,dc=idm,dc=homelab
      objectClass: groupOfNames
      objectClass: posixGroup
      cn: app_disabled
      gidNumber: 6300
      member: uid=${random_password.openldap_test_disabled_username.result},ou=people,dc=idm,dc=homelab
    EOF
  }
}
