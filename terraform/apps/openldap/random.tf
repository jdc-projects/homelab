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

resource "random_password" "openldap_config_admin_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "openldap_config_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
