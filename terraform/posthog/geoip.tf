locals {
  geoip_deployments = ["livestream", "feature-flags", "cymbal"]
}

resource "kubernetes_persistent_volume_claim" "geoip" {
  metadata {
    name      = "geoip-data"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-bulk-no-backup"

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_job" "geoip_download" {
  metadata {
    name      = "geoip-download"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = { app = "geoip-download" }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          image = local.kubectl_image
          name  = "geoip-download"

          command = [
            "/bin/sh", "-c",
            <<-EOT
              apk add --no-cache curl brotli
              curl -L "https://mmdbcdn.posthog.net/" --http1.1 --fail |
                brotli --decompress --output=/share/GeoLite2-City.mmdb
              chmod 644 /share/GeoLite2-City.mmdb
              echo "GeoLite2-City.mmdb downloaded successfully"
            EOT
          ]

          volume_mount {
            name       = "geoip"
            mount_path = "/share"
          }
        }

        volume {
          name = "geoip"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.geoip.metadata[0].name
          }
        }
      }
    }

    backoff_limit              = 4
    ttl_seconds_after_finished = 86400
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

resource "kubernetes_service_account" "geoip_refresh" {
  metadata {
    name      = "geoip-refresh"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
}

resource "kubernetes_role" "geoip_refresh" {
  metadata {
    name      = "geoip-refresh"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  rule {
    api_groups     = ["apps"]
    resources      = ["deployments"]
    verbs          = ["patch", "get"]
    resource_names = local.geoip_deployments
  }
}

resource "kubernetes_role_binding" "geoip_refresh" {
  metadata {
    name      = "geoip-refresh"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.geoip_refresh.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.geoip_refresh.metadata[0].name
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
}

resource "kubernetes_manifest" "geoip_refresh_cronjob" {
  manifest = {
    apiVersion = "batch/v1"
    kind       = "CronJob"

    metadata = {
      name      = "geoip-refresh"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      schedule                   = "0 3 1 * *"
      concurrencyPolicy          = "Replace"
      successfulJobsHistoryLimit = 1
      failedJobsHistoryLimit     = 1

      jobTemplate = {
        spec = {
          template = {
            spec = {
              restartPolicy      = "OnFailure"
              serviceAccountName = kubernetes_service_account.geoip_refresh.metadata[0].name

              containers = [
                {
                  name  = "geoip-refresh"
                  image = local.kubectl_image

                  command = [
                    "/bin/sh", "-c",
                    <<-EOT
                      set -e
                      apk add --no-cache curl brotli
                      curl -L "https://mmdbcdn.posthog.net/" --http1.1 --fail |
                        brotli --decompress --output=/share/GeoLite2-City.mmdb.new
                      chmod 644 /share/GeoLite2-City.mmdb.new
                      mv /share/GeoLite2-City.mmdb.new /share/GeoLite2-City.mmdb
                      echo "GeoLite2-City.mmdb refreshed, restarting deployments..."
                      kubectl rollout restart ${join(" ", [for d in local.geoip_deployments : "deploy/${d}"])} -n ${kubernetes_namespace.posthog.metadata[0].name}
                    EOT
                  ]

                  volumeMounts = [
                    {
                      name      = "geoip"
                      mountPath = "/share"
                    }
                  ]
                }
              ]

              volumes = [
                {
                  name = "geoip"
                  persistentVolumeClaim = {
                    claimName = kubernetes_persistent_volume_claim.geoip.metadata[0].name
                  }
                }
              ]
            }
          }
        }
      }
    }
  }
}
