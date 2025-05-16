resource "kubernetes_config_map" "omada_env" {
  metadata {
    name      = "omada-env"
    namespace = kubernetes_namespace.omada.metadata[0].name
  }

  data = {
    MANAGE_HTTP_PORT   = 30088
    MANAGE_HTTPS_PORT  = 30043
    PORTAL_HTTP_PORT   = 30088
    PORTAL_HTTPS_PORT  = 30843
    PORT_ADOPT_V1      = 30812
    PORT_APP_DISCOVERY = 30001
    PORT_DISCOVERY     = 30810
    PORT_MANAGER_V1    = 30811
    PORT_MANAGER_V2    = 30814
    PORT_TRANSFER_V2   = 30815
    PORT_RTTY          = 30816
    PORT_UPGRADE_V1    = 30813
    TZ                 = "Europe/London"
  }
}

resource "kubernetes_deployment" "omada" {
  metadata {
    name      = "omada"
    namespace = kubernetes_namespace.omada.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "omada"
      }
    }

    template {
      metadata {
        labels = {
          app = "omada"
        }
      }

      spec {
        container {
          image = "mbentley/omada-controller:5.15.20.20"
          name  = "omada"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.omada_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/opt/tplink/EAPController/data"
          }

          resources {
            requests = {
              cpu    = "1"
              memory = "2Gi"
            }

            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.omada.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.omada_env,
    ]
  }
}

module "omada_ingress" {
  source = "../modules/ingress"

  name      = "omada"
  namespace = kubernetes_namespace.omada.metadata[0].name
  domain    = "omada.${var.server_base_domain}"

  target_port    = kubernetes_config_map.omada_env.data.MANAGE_HTTPS_PORT
  is_scheme_http = false

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true

  selector = {
    app = "omada"
  }
}
