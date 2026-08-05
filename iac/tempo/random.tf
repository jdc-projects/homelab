# RustFS root credentials, used both to run the server and by Tempo's S3
# client directly (single-tenant homelab -> no separate readwrite app user).
# Mirrors iac/outline/credentials.tf.
resource "random_password" "rustfs_root_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "rustfs_root_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
