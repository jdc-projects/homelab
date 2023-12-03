resource "random_password" "jwt_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "machine_auth_api_key" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "storage_system_api_key" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "storage_system_jwt_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "transfer_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "thumbnails_transfer_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}
