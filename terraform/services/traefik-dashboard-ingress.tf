resource "kubernetes_namespace" "traefik_dashboard" {
  metadata {
    name = "traefik-dashboard"
  }
}

module "traefik_dashboard" {
  source = "../modules/external-auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.traefik_dashboard.metadata[0].name
  external_name      = "192.168.1.200"
  external_scheme    = "http"
  external_port      = 9000
  url_subdomain      = "traefik"
}
