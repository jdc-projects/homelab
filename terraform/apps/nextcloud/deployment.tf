
resource "kubernetes_config_map" "nextcloud_configmap" {
  metadata {
    name      = "nextcloud"
    namespace = kubernetes_namespace.nextcloud_namespace.metadata[0].name
  }

  data = {
    SQLITE_DATABASE           = "nextcloud"
    NEXTCLOUD_DATA_DIR        = "/var/www/html/data"
    NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud.${var.server_base_domain}"
  }
}

resource "kubernetes_secret" "nextcloud_secret" {
  metadata {
    name      = "nextcloud"
    namespace = kubernetes_namespace.nextcloud_namespace.metadata[0].name
  }

  data = {
    NEXTCLOUD_ADMIN_USER     = var.nextcloud_admin_username
    NEXTCLOUD_ADMIN_PASSWORD = var.nextcloud_admin_password
  }
}

resource "kubernetes_deployment" "nextcloud_deployment" {
  metadata {
    name      = "nextcloud"
    namespace = kubernetes_namespace.nextcloud_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nextcloud"
      }
    }

    template {
      metadata {
        labels = {
          app = "nextcloud"
        }
      }

      spec {
        container {
          image = "nextcloud:24.0.11-apache"
          name  = "nextcloud"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.nextcloud_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.nextcloud_secret.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/var/www/html/data"
            name       = "nextcloud-data"
          }
        }

        volume {
          name = "nextcloud-data"

          host_path {
            path = truenas_dataset.nextcloud_dataset.mount_point
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.nextcloud_configmap,
      kubernetes_secret.nextcloud_secret
    ]
  }
}
