resource "kubernetes_manifest" "clickhouse" {
  manifest = {
    apiVersion = "clickhouse.altinity.com/v1"
    kind       = "ClickHouseInstallation"

    metadata = {
      name      = "clickhouse"
      namespace = kubernetes_namespace.sentry.metadata[0].name
    }

    spec = {
      configuration = {
        clusters = [
          {
            name = "sentry"
            layout = {
              shardsCount   = 1
              replicasCount = 1
            }
          }
        ]
        users = {
          "default/password" = ""
          "default/networks/ip" = [
            "::/0"
          ]
          "default/profile" = "default"
          "default/quota"   = "default"
        }
        profiles = {
          "default/max_memory_usage" = "10000000000"
        }
        quotas = {
          "default/interval/duration"       = 3600
          "default/interval/queries"        = 0
          "default/interval/errors"         = 0
          "default/interval/result_rows"    = 0
          "default/interval/read_rows"      = 0
          "default/interval/execution_time" = 0
        }
        zookeeper = {
          nodes = [
            {
              host = "sentry-clickhouse-zookeeper" # ***** where is this coming from??
              port = 2181
            }
          ]
        }
      }

      templates = {
        podTemplates = [
          {
            name = "sentry-clickhouse-pod"
            spec = {
              containers = [
                {
                  name  = "clickhouse"
                  image = "clickhouse/clickhouse-server:25.8.12.129-alpine"
                  resources = {
                    requests = {
                      memory = "256Mi"
                      cpu    = "100m"
                    }
                    limits = {
                      memory = "2Gi"
                      cpu    = "1000m"
                    }
                  }
                }
              ]
            }
          }
        ]
        volumeClaimTemplates = [
          {
            name = "storage"
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = "openebs-zfs-localpv-bulk"
              resources = {
                requests = {
                  storage = "30Gi"
                }
              }
            }
          }
        ]
        serviceTemplates = [
          {
            name = "service"
            spec = {
              ports = [
                {
                  name = "http"
                  port = 8123
                },
                {
                  name = "tcp"
                  port = 9000
                }
              ]
            }
          }
        ]
      }
    }
  }

  field_manager {
    force_conflicts = true
  }

  wait {
    fields = {
      "status.status" = "Completed"
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
