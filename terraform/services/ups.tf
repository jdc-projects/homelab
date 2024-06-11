resource "kubernetes_namespace" "ups" {
  metadata {
    name = "ups"
  }
}

module "ups_ingress" {
  source = "../modules/external-auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.ups.metadata[0].name
  external_name      = "192.168.1.160"
  external_scheme    = "https"
  external_port      = 443
  url_subdomain      = "ups"
}
