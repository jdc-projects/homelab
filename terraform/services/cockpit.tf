resource "kubernetes_namespace" "cockpit" {
  metadata {
    name = "cockpit"
  }
}

module "cockpit_ingress" {
  source = "../modules/external-auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.cockpit.metadata[0].name
  external_name      = var.k3s_ip_address
  external_scheme    = "http"
  external_port      = 9090
  url_subdomain      = "cockpit"
}
