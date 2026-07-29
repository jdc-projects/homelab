locals {
  temporal_config = merge(
    {
      DB                       = "postgres12"
      DB_PORT                  = "5432"
      POSTGRES_USER            = "temporal"
      POSTGRES_SEEDS           = "${kubernetes_manifest.temporal_db.manifest.metadata.name}-rw"
      DYNAMIC_CONFIG_FILE_PATH = "config/dynamicconfig/development-sql.yaml"
    },
    var.es_host != null ? {
      ENABLE_ES  = "true"
      ES_SEEDS   = var.es_host
      ES_VERSION = var.es_version
      } : {
      ENABLE_ES = "false"
    }
  )
}

resource "kubernetes_config_map" "temporal_dynamic_config" {
  metadata {
    name      = "${var.name_prefix}-dynamic-config"
    namespace = var.namespace
  }

  data = {
    "development-sql.yaml" = <<-EOT
      limit.maxIDLength:
          - value: 255
            constraints: {}
      system.forceSearchAttributesCacheRefreshOnRead:
          - value: true
            constraints: {}
      system.visibilityDisableOrderByClause:
          - value: false
            constraints: {}
    EOT
  }
}

resource "kubernetes_config_map" "temporal_config" {
  metadata {
    name      = "${var.name_prefix}-config"
    namespace = var.namespace
  }

  data = local.temporal_config
}

resource "kubernetes_deployment" "temporal" {
  metadata {
    name      = var.name_prefix
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.name_prefix
      }
    }

    template {
      metadata {
        labels = {
          app = var.name_prefix
        }
      }

      spec {
        container {
          image = var.server_image
          name  = var.name_prefix

          env_from {
            config_map_ref {
              name = kubernetes_config_map.temporal_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.temporal_secrets.metadata[0].name
            }
          }

          volume_mount {
            name       = "dynamic-config"
            mount_path = "/etc/temporal/config/dynamicconfig"
          }

          port {
            container_port = 7233
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }

        volume {
          name = "dynamic-config"
          config_map {
            name = kubernetes_config_map.temporal_dynamic_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "temporal" {
  metadata {
    name      = var.name_prefix
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.name_prefix
    }

    port {
      port        = 7233
      target_port = 7233
    }
  }
}
