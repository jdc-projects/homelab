resource "kubernetes_namespace" "truenas" {
  metadata {
    name = "truenas"
  }
}

module "truenas_ingress" {
  source = "../modules/external-auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.truenas.metadata[0].name
  external_name      = "192.168.1.250"
  external_scheme    = "https"
  external_port      = 443
  url_subdomain      = "nas"
}
