locals {
  cap_domain = "cap.${var.server_base_domain}"
}

# Dashboard login key. Cap Standalone authenticates the admin dashboard at "/"
# via this single key (cookie session), in addition to the OIDC layer the
# ingress puts in front of it. Retrieve it with:
#   kubectl -n cap get secret cap-env -o jsonpath='{.data.ADMIN_KEY}' | base64 -d
resource "random_password" "cap_admin_key" {
  length  = 40
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "cap_env" {
  metadata {
    name      = "cap-env"
    namespace = kubernetes_namespace.cap.metadata[0].name
  }

  data = {
    ADMIN_KEY = random_password.cap_admin_key.result
    REDIS_URL = "redis://valkey:6379"
    # Cap matches CORS origins by exact string only (no wildcards/regex), so a
    # global allow-all is the safe default; lock each site key to its concrete
    # origin in the dashboard (Configuration tab) instead. See README.md.
    CORS_ORIGIN = "*"
    # Traefik sets X-Forwarded-For; Cap trusts it as-is, which is correct here
    # because the service is a ClusterIP only reachable via the ingress.
    RATELIMIT_IP_HEADER = "X-Forwarded-For"
  }
}

# Persistent storage for the optional IP-to-country/ASN GeoIP mmdb files that
# Cap downloads into /usr/src/app/data (UID 1000). The pod runs as UID/GID 1000
# with fsGroup 1000 (see the deployment) so the mount is writable by bun.
resource "kubernetes_persistent_volume_claim" "cap_data" {
  metadata {
    name      = "cap-data"
    namespace = kubernetes_namespace.cap.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    storage_class_name = "openebs-zfs-localpv-random"
  }
}

resource "kubernetes_deployment" "cap" {
  metadata {
    name      = "cap"
    namespace = kubernetes_namespace.cap.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cap"
      }
    }

    template {
      metadata {
        labels = {
          app = "cap"
        }
      }

      spec {
        security_context {
          run_as_user  = 1000
          run_as_group = 1000
          fs_group     = 1000
        }

        container {
          image = "tiago2/cap:3.1.9"
          name  = "cap"

          env_from {
            secret_ref {
              name = kubernetes_secret.cap_env.metadata[0].name
            }
          }

          port {
            container_port = 3000
            name           = "http"
          }

          volume_mount {
            name       = "cap-data"
            mount_path = "/usr/src/app/data"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }

            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "1"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "cap-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.cap_data.metadata[0].name
          }
        }
      }
    }
  }

  # Roll the pod when the env secret changes (e.g. ADMIN_KEY rotation).
  lifecycle {
    replace_triggered_by = [
      kubernetes_secret.cap_env,
    ]
  }
}
