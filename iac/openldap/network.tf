resource "kubernetes_service" "openldap" {
  metadata {
    name      = "openldap"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  spec {
    selector = {
      app = "openldap"
    }

    port {
      port        = "1389"
      target_port = kubernetes_config_map.openldap_env.data.LDAP_PORT_NUMBER
    }
  }
}

resource "kubernetes_manifest" "openldap_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRouteTCP"

    metadata = {
      name      = "openldap"
      namespace = kubernetes_namespace.openldap.metadata[0].name
    }

    spec = {
      entryPoints = ["ldaps"]

      routes = [{
        match = "HostSNI(`*`)"

        services = [{
          name      = kubernetes_service.openldap.metadata[0].name
          namespace = kubernetes_namespace.openldap.metadata[0].name
          port      = kubernetes_service.openldap.spec[0].port[0].port
        }]

        middleware = [
          "cloudflare-real-ip",
          "geoblock",
          "crowdsec-bouncer",
        ]
      }]

      tls = {
      }
    }
  }
}
