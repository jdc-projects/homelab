resource "random_password" "minio_root_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "minio_root_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "minio_access_key" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "minio_secret_key" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_secret_key" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_core_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_jobservice_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "harbor_registry_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
