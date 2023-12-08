resource "kubernetes_namespace" "idrac_fan_controller" {
  metadata {
    name = "idrac-fan-controller"
  }
}

resource "kubernetes_secret" "idrac_fan_controller_env" {
  metadata {
    name      = "idrac-fan-controller-access"
    namespace = kubernetes_namespace.idrac_fan_controller.metadata[0].name
  }

  data = {
    IDRAC_USERNAME = var.idrac_username
    IDRAC_PASSWORD = var.idrac_password
  }
}

resource "kubernetes_config_map" "idrac_fan_controller_env" {
  metadata {
    name      = "idrac-fan-controller-access"
    namespace = kubernetes_namespace.idrac_fan_controller.metadata[0].name
  }

  data = {
    IDRAC_HOST                                                  = "192.168.1.180"
    FAN_SPEED                                                   = "5"
    CPU_TEMPERATURE_THRESHOLD                                   = "60"
    CHECK_INTERVAL                                              = "60"
    DISABLE_THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE = "false"
  }
}

resource "kubernetes_deployment" "idrac_fan_controller_deployment" {
  metadata {
    name      = "idrac-fan-controller"
    namespace = kubernetes_namespace.idrac_fan_controller.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "idrac-fan-controller"
      }
    }

    template {
      metadata {
        labels = {
          app = "idrac-fan-controller"
        }
      }

      spec {
        container {
          image = "tigerblue77/dell_idrac_fan_controller:latest"
          name  = "idrac-fan-controller"

          env_from {
            secret_ref {
              name = kubernetes_secret.idrac_fan_controller_env.metadata[0].name
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.idrac_fan_controller_env.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}
