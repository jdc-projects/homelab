resource "kubernetes_namespace" "vaultwarden_namespace" {
  metadata {
    name = "vaultwarden"
  }
}

resource "kubernetes_config_map" "vaultwarden_configmap" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  data = {
    WEBSOCKET_ENABLED        = "true"
    WEBSOCKET_PORT           = "3012"
    EMERGENCY_ACCESS_ALLOWED = "false"
    SIGNUPS_ALLOWED          = "false"
    SIGNUPS_VERIFY           = "false"
    INVITATIONS_ALLOWED      = "false"
    PASSWORD_HINTS_ALLOWED   = "false"
    DOMAIN                   = "https://vault.${var.server_base_domain}"
    ROCKET_PORT              = "80"
  }
}

resource "truenas_dataset" "vaultwarden_dataset" {
  pool               = "vault"
  name               = "vaultwarden"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment" "vaultwarden_deployment" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vaultwarden"
      }
    }

    template {
      metadata {
        labels = {
          app = "vaultwarden"
        }
      }

      spec {
        container {
          image = "vaultwarden/server:1.28.0"
          name  = "vaultwarden"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.vaultwarden_configmap.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/data"
            name       = "vaultwarden-data"
          }
        }

        volume {
          name = "vaultwarden-data"

          host_path {
            path = truenas_dataset.vaultwarden_dataset.mount_point
          }
        }
      }
    }
  }
}
