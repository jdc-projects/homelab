resource "kubernetes_namespace" "ups" {
  metadata {
    name = "ups"
  }
}

module "ups_ingress" {
  source = "../modules/ingress"

  name        = "ups"
  namespace   = kubernetes_namespace.ups.metadata[0].name
  domain      = "ups.${var.server_base_domain}"
  target_port = 443

  external_name = "192.168.1.160"

  is_external_scheme_http = false

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true
}
