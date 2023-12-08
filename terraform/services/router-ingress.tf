resource "kubernetes_namespace" "router" {
  metadata {
    name = "router"
  }
}

module "router_ingress" {
  source = "../modules/external-auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.pve.metadata[0].name
  external_name      = "192.168.1.1"
  external_scheme    = "https"
  external_port      = 444
  url_subdomain      = "router"
}
