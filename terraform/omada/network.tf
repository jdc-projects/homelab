resource "kubernetes_service" "omada_nodeport" {
  for_each = tomap({
    manage-http = tomap({
      port_number = kubernetes_config_map.omada_env.data.MANAGE_HTTP_PORT
      protocol    = "TCP"
    })
    manage-https = tomap({
      port_number = kubernetes_config_map.omada_env.data.MANAGE_HTTPS_PORT
      protocol    = "TCP"
    })
    # uses the same port as PORT_ADOPT_V1
    # portal-http = tomap({
    #   port_number = kubernetes_config_map.omada_env.data.PORTAL_HTTP_PORT
    #   protocol = "TCP"
    # })
    portal-https = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORTAL_HTTPS_PORT
      protocol    = "TCP"
    })
    adopt-v1 = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_ADOPT_V1
      protocol    = "TCP"
    })
    app-discovery = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_APP_DISCOVERY
      protocol    = "UDP"
    })
    discovery = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_DISCOVERY
      protocol    = "UDP"
    })
    manager-v1 = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_MANAGER_V1
      protocol    = "TCP"
    })
    manager-v2 = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_MANAGER_V2
      protocol    = "TCP"
    })
    transfer-v2 = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_TRANSFER_V2
      protocol    = "TCP"
    })
    rtty = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_RTTY
      protocol    = "TCP"
    })
    upgrade-v1 = tomap({
      port_number = kubernetes_config_map.omada_env.data.PORT_UPGRADE_V1
      protocol    = "TCP"
    })
  })

  metadata {
    name      = "${each.key}-nodeport"
    namespace = kubernetes_namespace.omada.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      app = "omada"
    }

    port {
      port        = each.value.port_number
      target_port = each.value.port_number
      node_port   = each.value.port_number
      protocol    = each.value.protocol
    }
  }
}
