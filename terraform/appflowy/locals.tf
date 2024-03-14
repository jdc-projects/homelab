locals {
  appflowy_version      = "0.12.2"
  appflowy_domain       = "appflowy.${var.server_base_domain}"
  gotrue_port           = 9999
  appflowy_db_instances = 2
}
