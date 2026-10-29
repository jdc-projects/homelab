# OpenBao server via the official helm chart: standalone (single replica —
# no HA on a single-node cluster; durability comes from the CNPG-backed
# postgresql storage backend) with an auto-unseal sidecar.
#
# Sealing design (see README.md for the full rationale):
#   - init happens once, in-cluster, via kubernetes_job.openbao_bootstrap
#     (1 key-share), which writes:
#       openbao-seal      (unseal key)  -> consumed by the sidecar below
#       openbao-bootstrap (root token)  -> consumed by iac/openbao-config
#   - the sidecar re-unseals on every start / restart / hibernation wake, so
#     no manual unsealing is ever needed.
locals {
  openbao_server_config = <<-EOT
    ui = true

    listener "tcp" {
      address     = "[::]:8200"
      tls_disable = 1

      telemetry {
        # In-cluster Prometheus ServiceMonitor scrapes /v1/sys/metrics
        # unauthenticated (edge TLS terminates at Traefik; this listener is
        # cluster-internal only).
        unauthenticated_metrics_access = "true"
      }
    }

    # Top-level telemetry stanza is REQUIRED for /v1/sys/metrics to serve
    # Prometheus format — without it the endpoint 400s ("prometheus is not
    # enabled") and the ServiceMonitor target stays down. The listener-level
    # telemetry block above only lifts authentication.
    telemetry {
      prometheus_retention_time = "24h"
      disable_hostname          = true
    }

    storage "postgresql" {
      # Injected at runtime via BAO_PG_CONNECTION_URL (db-credentials secret,
      # wired through server.extraSecretEnvironmentVars below).
      connection_url = ""

      # Retry forever: OpenBao may (re)start while openbao-db is still waking
      # up (hibernation resume, node boot) and must not exit before the DB is
      # reachable.
      max_connect_retries = 0
    }

    # Declarative audit device (OpenBao 2.x: the sys/audit API is gone, so
    # this can NOT be managed from iac/openbao-config via the vault provider).
    # Writes to the auditStorage PVC.
    audit "file" "file" {
      description = "Audit log (auditStorage PVC)."
      options {
        file_path = "/openbao/audit/audit.log"
      }
    }
  EOT

  # Auto-unseal sidecar: polls seal status and unseals with the key from the
  # openbao-seal secret (created by the bootstrap job). The secret volume is
  # optional so the pod can start before the secret exists (first boot).
  openbao_unseal_sidecar = {
    name  = "unseal"
    image = "quay.io/openbao/openbao:${local.openbao_image_tag}"

    command = ["/bin/sh", "-c"]
    args = [
      <<-EOT
        # Hot path is busybox wget+grep (sub-millisecond CPU) — invoking the
        # `bao` CLI every poll starts a fresh Go binary whose startup burst
        # blows any CPU limit's per-period quota and trips CPUThrottlingHigh
        # (~80% of active cfs periods throttled even at 250m). The CLI is
        # only used in the rare sealed -> unseal path.
        while true; do
          if [ -f /openbao/seal/unseal-key ]; then
            # seal-status is unauthenticated; "sealed":true means rc would
            # be 2 from `bao status` (0 = unsealed, 1 = error e.g. storage
            # down — wget fails, nothing to do, retry next tick).
            if wget -qO- "$${BAO_ADDR}/v1/sys/seal-status" 2>/dev/null | grep -q '"sealed":true'; then
              echo "sealed; unsealing..."
              bao operator unseal "$(cat /openbao/seal/unseal-key)" >/dev/null 2>&1 || true
            fi
          fi
          sleep 10
        done
      EOT
    ]

    env = [
      {
        name  = "BAO_ADDR"
        value = "http://127.0.0.1:8200"
      },
    ]

    volumeMounts = [
      {
        name      = "seal"
        mountPath = "/openbao/seal"
        readOnly  = true
      },
    ]

    # Limits sized for the rare `bao operator unseal` invocation (Go binary
    # startup burst); the wget+grep poll loop itself is sub-millisecond.
    # History: a 100m limit on a `bao status`-per-poll loop throttled to
    # ~92% of cfs periods (CPUThrottlingHigh) — see the script comment above.
    resources = {
      requests = {
        cpu    = "25m"
        memory = "64Mi"
      }

      limits = {
        cpu    = "250m"
        memory = "128Mi"
      }
    }
  }
}

resource "helm_release" "openbao" {
  name      = "openbao"
  namespace = kubernetes_namespace.openbao.metadata[0].name

  repository = "https://openbao.github.io/openbao-helm"
  chart      = "openbao"
  version    = local.openbao_chart_version

  timeout = 300

  values = [
    yamlencode({
      # Deterministic resource names (service "openbao", statefulset "openbao").
      fullnameOverride = "openbao"

      global = {
        tlsDisable = true
      }

      # Agent injector: PURPOSEFULLY not deployed. The intended consumers are
      # applications, not the cluster itself — enable (and wire its k8s-auth
      # role) when the first consumer lands. See README.md.
      injector = {
        enabled = false
      }

      csi = {
        enabled = false
      }

      server = {
        image = {
          registry   = "quay.io"
          repository = "openbao/openbao"
          tag        = local.openbao_image_tag
        }

        logFormat = "json"

        # Sealed/uninitialized pods report Ready so `helm --wait` settles on
        # first install (before the bootstrap job + unseal sidecar have run).
        # A Ready-but-sealed pod just 503s at the API for a few seconds.
        readinessProbe = {
          enabled = true
          path    = "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
        }

        standalone = {
          enabled = true
          config  = local.openbao_server_config
        }

        # Roll pods when the server config (configmap) changes — without this
        # checksum annotation the statefulset ignores configmap updates.
        configAnnotation = true

        # Data lives in Postgres, not on a local PVC.
        dataStorage = {
          enabled = false
        }

        # Audit log (enabled as a device from iac/openbao-config) writes here.
        auditStorage = {
          enabled      = true
          storageClass = "openebs-zfs-localpv-general-no-backup"
          accessMode   = "ReadWriteOnce"
          size         = "5Gi"
        }

        extraSecretEnvironmentVars = [
          {
            envName    = "BAO_PG_CONNECTION_URL"
            secretName = kubernetes_secret.db_credentials.metadata[0].name
            secretKey  = "connection-url"
          },
        ]

        volumes = [
          {
            name = "seal"
            secret = {
              secretName = "openbao-seal"
              optional   = true
            }
          },
        ]

        extraContainers = [
          local.openbao_unseal_sidecar,
        ]

        # Restart-safe: the unseal sidecar makes pod replacement self-healing.
        updateStrategyType = "RollingUpdate"

        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }

          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      serverTelemetry = {
        serviceMonitor = {
          enabled = true
        }
      }
    }),
  ]

  depends_on = [
    kubernetes_manifest.openbao_db,
    kubernetes_secret.db_credentials,
  ]
}
