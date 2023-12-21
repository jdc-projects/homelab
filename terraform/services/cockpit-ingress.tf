resource "kubernetes_namespace" "cockpit" {
  metadata {
    name = "cockpit"
  }
}

module "cockpit_ingress" {
  source = "../modules/external-auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.cockpit.metadata[0].name
  external_name      = "192.168.1.190"
  external_scheme    = "http"
  external_port      = 9090
  url_subdomain      = "cockpit"
}
