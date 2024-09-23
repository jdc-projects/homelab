resource "kubernetes_manifest" "cert_manager_certificate_wilcard" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "wildcard"
      namespace = kubernetes_namespace.traefik.metadata[0].name
    }

    spec = {
      secretName = "wildcard-cert"

      dnsNames = [
        "*.${var.server_base_domain}",
      ]

      issuerRef = {
        name = kubernetes_manifest.cert_manager_issuer_le_prod.manifest.metadata.name
        kind = kubernetes_manifest.cert_manager_issuer_le_prod.manifest.kind
      }
    }
  }
}
