resource "kubernetes_service" "keycloak_service" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "keycloak"
    }

    port {
      port        = "80"
      target_port = kubernetes_config_map.keycloak_configmap.data.KC_HTTP_PORT
    }
  }
}

resource "kubernetes_manifest" "keycloak_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "keycloak"
      namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`idp.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.keycloak_http_service.metadata[0].name
          namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
          port      = kubernetes_service.keycloak_http_service.spec[0].port[0].target_port
        }]
      }]
    }
  }
}
