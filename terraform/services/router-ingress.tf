resource "kubernetes_namespace" "router" {
  metadata {
    name = "router"
  }
}

module "router_ingress" {
  source = "../modules/ingress"

  name        = "router"
  namespace   = kubernetes_namespace.router.metadata[0].name
  domain      = "router.${var.server_base_domain}"
  target_port = 444

  external_name = "192.168.1.1"

  is_external_scheme_http = false

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true
}
