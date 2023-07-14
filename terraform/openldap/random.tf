resource "random_password" "openldap_admin_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "openldap_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "openldap_test_admin_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "openldap_test_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "openldap_test_user_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "openldap_test_user_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "openldap_test_guest_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "openldap_test_guest_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "openldap_test_disabled_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "openldap_test_disabled_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
