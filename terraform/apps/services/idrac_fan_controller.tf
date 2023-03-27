resource "kubernetes_namespace" "idrac_fan_controller_namespace" {
  metadata {
    name = "idrac-fan-controller"
  }
}

# secret for api key
resource "kubernetes_secret" "idrac_fan_controller_access_secret" {
  metadata {
    name      = "idrac-fan-controller-access"
    namespace = kubernetes_namespace.idrac_fan_controller_namespace.metadata[0].name
  }

  data = {
    IDRAC_USERNAME = var.idrac_username
    IDRAC_PASSWORD = var.idrac_password
  }
}

resource "kubernetes_deployment" "idrac_fan_controller_deployment" {
  metadata {
    name      = "idrac-fan-controller"
    namespace = kubernetes_namespace.idrac_fan_controller_namespace.metadata[0].name
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
              name = kubernetes_secret.idrac_fan_controller_access_secret.metadata[0].name
            }
          }

          env {
            name  = "IDRAC_HOST"
            value = "192.168.1.180"
          }
          env {
            name  = "FAN_SPEED"
            value = "5"
          }
          env {
            name  = "CPU_TEMPERATURE_THRESHOLD"
            value = "60"
          }
          env {
            name  = "CHECK_INTERVAL"
            value = "60"
          }
          env {
            name  = "DISABLE_THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE"
            value = "false"
          }
        }
      }
    }
  }
}
