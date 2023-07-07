resource "random_password" "openldap_admin_username" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "openldap_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
