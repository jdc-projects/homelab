resource "kubernetes_service" "truenas_service" {
  metadata {
    name      = "truenas"
    namespace = "traefik"
  }

  spec {
    external_name = "192.168.1.190"
    type          = "ExternalName"
  }
}

resource "kubernetes_manifest" "truenas_ingressroute" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "truenas"
      namespace = "traefik"
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`nas.jack-chapman.co.uk`)"
        services = [{
          name      = "truenas"
          namespace = "traefik"
          scheme    = "https"
          port      = 444
        }]
      }]
    }
  }
}
