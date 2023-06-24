resource "kubernetes_service" "keycloak_db_service" {
  metadata {
    name      = kubernetes_config_map.keycloak_configmap.data.KEYCLOAK_DATABASE_HOST
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "keycloak-db"
    }

    port {
      port        = 5432
      target_port = kubernetes_config_map.keycloak_configmap.data.KEYCLOAK_DATABASE_PORT
    }
  }
}

resource "kubernetes_service" "keycloak_service" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "keycloak"
    }

    port {
      port        = 80
      target_port = kubernetes_config_map.keycloak_configmap.data.KEYCLOAK_HTTP_PORT
    }
  }
}

resource "kubernetes_manifest" "keycloak_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "keycloak"
      namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`idp.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.keycloak_service.metadata[0].name
          namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
          port      = kubernetes_service.keycloak_service.spec[0].port[0].port
        }]
      }]
    }
  }
}
