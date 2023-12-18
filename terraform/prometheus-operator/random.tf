resource "random_password" "grafana_admin_password" {
  length  = 32
  numeric = true
  special = false
  upper   = true
}
