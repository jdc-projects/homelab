resource "kubernetes_service" "vaultwarden_webvault" {
  metadata {
    name      = "vaultwarden-webvault"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  spec {
    selector = {
      app = "vaultwarden"
    }

    port {
      port        = kubernetes_config_map.vaultwarden_env.data.ROCKET_PORT
      target_port = kubernetes_config_map.vaultwarden_env.data.ROCKET_PORT
    }
  }
}

resource "kubernetes_manifest" "vaultwarden_webvault_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "vaultwarden-webvault"
      namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`vault.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.vaultwarden_webvault.metadata[0].name
          namespace = kubernetes_namespace.vaultwarden.metadata[0].name
          port      = kubernetes_service.vaultwarden_webvault.spec[0].port[0].port
        }]
      }]
    }
  }
}
