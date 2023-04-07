
resource "kubernetes_config_map" "ocis_configmap" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
  }
}

resource "kubernetes_secret" "ocis_secret" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
  }
}

resource "kubernetes_deployment" "ocis_deployment" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ocis"
      }
    }

    template {
      metadata {
        labels = {
          app = "ocis"
        }
      }

      spec {
        container {
          image = "owncloud/ocis:2.0.0"
          name  = "ocis"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.ocis_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.ocis_secret.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/var/www/html"
            name       = "ocis-data"
          }
        }

        volume {
          name = "ocis-data"

          host_path {
            path = truenas_dataset.ocis_dataset.mount_point
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.ocis_configmap,
      kubernetes_secret.ocis_secret
    ]
  }
}
