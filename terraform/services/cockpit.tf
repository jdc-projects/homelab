resource "kubernetes_namespace" "cockpit" {
  metadata {
    name = "cockpit"
  }
}

module "cockpit_ingress" {
  source = "../modules/ingress"

  name        = "cockpit"
  namespace   = kubernetes_namespace.cockpit.metadata[0].name
  domain      = "cockpit.${var.server_base_domain}"
  target_port = 9090

  external_name = var.k3s_ip_address

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true
}
