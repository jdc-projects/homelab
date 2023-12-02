resource "kubernetes_namespace" "truenas" {
  metadata {
    name = "truenas"
  }
}

resource "kubernetes_service" "truenas" {
  metadata {
    name      = "truenas"
    namespace = kubernetes_namespace.truenas.metadata[0].name
  }

  spec {
    external_name = "192.168.1.250"
    type          = "ExternalName"
  }
}

resource "kubernetes_manifest" "truenas_ingressroute" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "truenas"
      namespace = kubernetes_namespace.truenas.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`nas.${var.server_base_domain}`)"
        services = [{
          name      = "truenas"
          namespace = kubernetes_namespace.truenas.metadata[0].name
          scheme    = "https"
          port      = 443
        }]
      }]
    }
  }
}
