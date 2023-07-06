resource "kubernetes_deployment" "ocis" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis.metadata[0].name
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
          image = "owncloud/ocis:3.0.0"
          name  = "ocis"

          volume_mount {
            mount_path = "/etc/ocis/"
            name       = "ocis-config"
          }

        #   volume_mount {
        #     mount_path = "/var/lib/ocis/"
        #     name       = "ocis-data"
        #   }
        }

        volume {
          name = "ocis-config"

          config_map {
            name = kubernetes_secret.ocis_config_files.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_secret.ocis_config_files
    ]
  }
}