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

resource "kubernetes_service" "vaultwarden_websocket" {
  metadata {
    name      = "vaultwarden-websocket"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  spec {
    selector = {
      app = "vaultwarden"
    }

    port {
      port        = kubernetes_config_map.vaultwarden_env.data.WEBSOCKET_PORT
      target_port = kubernetes_config_map.vaultwarden_env.data.WEBSOCKET_PORT
    }
  }
}

resource "kubernetes_manifest" "vaultwarden_webvault_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
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

resource "kubernetes_manifest" "vaultwarden_webvault_negotiate_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "vaultwarden-webvault-negotiate"
      namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind     = "Rule"
        priority = "20"
        match    = "Host(`vault.${var.server_base_domain}`) && Path(`/notifications/hub/negotiate`)"
        services = [{
          name      = kubernetes_service.vaultwarden_webvault.metadata[0].name
          namespace = kubernetes_namespace.vaultwarden.metadata[0].name
          port      = kubernetes_service.vaultwarden_webvault.spec[0].port[0].port
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "vaultwarden_websocket_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "vaultwarden-websocket"
      namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind     = "Rule"
        priority = "10"
        match    = "Host(`vault.${var.server_base_domain}`) && Path(`/notifications/hub`)"
        services = [{
          name      = kubernetes_service.vaultwarden_websocket.metadata[0].name
          namespace = kubernetes_namespace.vaultwarden.metadata[0].name
          port      = kubernetes_service.vaultwarden_websocket.spec[0].port[0].port
        }]
      }]
    }
  }
}
