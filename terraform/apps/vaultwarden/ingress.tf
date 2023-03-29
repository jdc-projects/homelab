resource "kubernetes_service" "vaultwarden_webvault_service" {
  metadata {
    name      = "vaultwarden-webvault"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "vaultwarden"
    }

    port {
      port        = kubernetes_config_map.vaultwarden_configmap.data.ROCKET_PORT
      target_port = kubernetes_config_map.vaultwarden_configmap.data.ROCKET_PORT
    }
  }

  depends_on = [
    kubernetes_deployment.vaultwarden_deployment
  ]
}

resource "kubernetes_service" "vaultwarden_websocket_service" {
  metadata {
    name      = "vaultwarden-websocket"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "vaultwarden"
    }

    port {
      port        = kubernetes_config_map.vaultwarden_configmap.data.WEBSOCKET_PORT
      target_port = kubernetes_config_map.vaultwarden_configmap.data.WEBSOCKET_PORT
    }
  }

  depends_on = [
    kubernetes_deployment.vaultwarden_deployment
  ]
}

resource "kubernetes_manifest" "vaultwarden_webvault_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "vaultwarden-webvault"
      namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`vault.${var.server_base_domain}`) && (Path(`/`) || Path(`/notifications/hub`))"
        services = [{
          name      = kubernetes_service.vaultwarden_webvault_service.metadata[0].name
          namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
          port      = kubernetes_service.vaultwarden_webvault_service.spec[0].port[0].target_port
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
      namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`vault.${var.server_base_domain}`) && Path(`/notifications/hub`)"
        services = [{
          name      = kubernetes_service.vaultwarden_websocket_service.metadata[0].name
          namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
          port      = kubernetes_service.vaultwarden_websocket_service.spec[0].port[0].target_port
        }]
      }]
    }
  }
}
