resource "random_uuid" "system_user_id" {
}

resource "random_uuid" "storage_users_mount_id" {
}

resource "random_password" "jwt_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "transfer_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "machine_auth_api_key" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "system_user_api_key" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "idm_svc_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "idm_revasvc_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "idm_idpsvc_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
