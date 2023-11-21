resource "kubernetes_namespace" "pve" {
  metadata {
    name = "pve"
  }
}

resource "kubernetes_service" "pve" {
  metadata {
    name      = "pve"
    namespace = kubernetes_namespace.pve.metadata[0].name
  }

  spec {
    external_name = "192.168.1.200"
    type          = "ExternalName"
  }
}

resource "kubernetes_manifest" "pve_ingressroute" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "pve"
      namespace = kubernetes_namespace.pve.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`pve.${var.server_base_domain}`)"
        services = [{
          name      = "pve"
          namespace = kubernetes_namespace.pve.metadata[0].name
          scheme    = "https"
          port      = 8006
        }]
      }]
    }
  }
}
