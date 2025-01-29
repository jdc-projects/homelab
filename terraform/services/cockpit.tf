resource "kubernetes_namespace" "cockpit" {
  metadata {
    name = "cockpit"
  }
}

# user encounters error when trying to login to cockpit, but keeping the ingress so I can fix it later
module "cockpit_ingress" {
  source = "../modules/ingress"

  name        = "cockpit"
  namespace   = kubernetes_namespace.cockpit.metadata[0].name
  domain      = "cockpit.${var.server_base_domain}"
  target_port = 9090

  external_name = "192.168.100.190"

  is_external_scheme_http = false

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true
}
