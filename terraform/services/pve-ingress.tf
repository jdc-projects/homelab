resource "kubernetes_namespace" "pve" {
  metadata {
    name = "pve"
  }
}

module "pve_ingress" {
  source = "../modules/external-auth-ingress"

  server_base_domain = var.server_base_domain
  namespace          = kubernetes_namespace.pve.metadata[0].name
  external_name      = "192.168.1.190"
  external_scheme    = "https"
  external_port      = 8006
  url_subdomain      = "pve"
}
