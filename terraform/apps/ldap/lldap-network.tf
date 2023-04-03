resource "kubernetes_service" "lldap_ldap_service" {
  metadata {
    name      = "lldap-ldap"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "lldap"
    }

    port {
      port        = kubernetes_config_map.lldap_configmap.data.LLDAP_LDAP_PORT
      target_port = kubernetes_config_map.lldap_configmap.data.LLDAP_LDAP_PORT
    }
  }
}

resource "kubernetes_service" "lldap_http_service" {
  metadata {
    name      = "lldap-http"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "lldap"
    }

    port {
      port        = "80"
      target_port = "80"
    }
  }
}

resource "kubernetes_manifest" "lldap_ldaps_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRouteTCP"

    metadata = {
      name      = "lldap-ldaps"
      namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["ldaps"]

      routes = [{
        match = "HostSNI(`*`)"
        services = [{
          name      = kubernetes_service.lldap_ldap_service.metadata[0].name
          namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
          port      = kubernetes_service.lldap_ldap_service.spec[0].port[0].port
        }]
      }]

      tls = {
      }
    }
  }
}

resource "kubernetes_manifest" "lldap_http_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "lldap-http"
      namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`idm.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.lldap_http_service.metadata[0].name
          namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
          port      = kubernetes_service.lldap_http_service.spec[0].port[0].target_port
        }]
      }]
    }
  }
}
