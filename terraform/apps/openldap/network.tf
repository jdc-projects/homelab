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
      port        = kubernetes_config_map.openldap_env.data.LDAP_PORT_NUMBER
      target_port = kubernetes_config_map.openldap_env.data.LDAP_PORT_NUMBER
    }
  }
}

# resource "kubernetes_service" "phpldapadmin" {
#   metadata {
#     name      = "phpldapadmin"
#     namespace = kubernetes_namespace.openldap.metadata[0].name
#   }

#   spec {
#     selector = {
#       app = "phpldapadmin"
#     }

#     port {
#       port        = "443"
#       target_port = "443"
#     }
#   }
# }

resource "kubernetes_manifest" "openldap_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRouteTCP"

    metadata = {
      name      = "openldap"
      namespace = kubernetes_namespace.openldap.metadata[0].name
    }

    spec = {
      entryPoints = ["ldaps-2"]

      routes = [{
        match = "HostSNI(`*`)"
        services = [{
          name      = kubernetes_service.openldap.metadata[0].name
          namespace = kubernetes_namespace.openldap.metadata[0].name
          port      = kubernetes_service.openldap.spec[0].port[0].port
        }]
      }]

      tls = {
      }
    }
  }
}

# resource "kubernetes_manifest" "phpldapadmin_ingress" {
#   manifest = {
#     apiVersion = "traefik.containo.us/v1alpha1"
#     kind       = "IngressRoute"

#     metadata = {
#       name      = "phpldapadmin"
#       namespace = kubernetes_namespace.openldap.metadata[0].name
#     }

#     spec = {
#       entryPoints = ["websecure"]

#       routes = [{
#         kind  = "Rule"
#         match = "Host(`idm2.${var.server_base_domain}`)"
#         services = [{
#           name      = kubernetes_service.phpldapadmin.metadata[0].name
#           namespace = kubernetes_namespace.openldap.metadata[0].name
#           port      = kubernetes_service.phpldapadmin.spec[0].port[0].port
#         }]
#       }]
#     }
#   }
# }
