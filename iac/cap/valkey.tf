# Backing Valkey for Cap's state (site keys, config, challenges, sessions,
# metrics, the RSW modulus). There is no shared/central Valkey in the cluster
# (iac/valkey-operator is a placeholder); every consumer runs its own release
# from the valkey.io Helm chart. Unlike outline/n8n, which use Valkey as an
# ephemeral cache, Cap uses it as its PRIMARY data store, so persistence is on.
#
# The PVC is declared separately from the chart (the repo's existingClaim
# pattern, mirroring iac/outline/rustfs.tf etc.) so that destroying the
# helm_release can never delete the data - its lifecycle is owned by tofu.
resource "kubernetes_persistent_volume_claim" "valkey_data" {
  metadata {
    name      = "valkey-data"
    namespace = kubernetes_namespace.cap.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "2Gi"
      }
    }

    storage_class_name = "openebs-zfs-localpv-random"
  }
}

resource "helm_release" "valkey" {
  name      = "valkey"
  namespace = kubernetes_namespace.cap.metadata[0].name

  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = "0.10.0"

  timeout = 300

  set = [
    { name = "metrics.enabled", value = "true" },
    { name = "metrics.serviceMonitor.enabled", value = "true" },
    # Mount the separately-declared PVC (existingClaim). requestedSize/className
    # are omitted - the chart only provisions its own PVC when they are set and
    # persistentVolumeClaimName is empty.
    { name = "dataStorage.enabled", value = "true" },
    { name = "dataStorage.persistentVolumeClaimName", value = kubernetes_persistent_volume_claim.valkey_data.metadata[0].name },
  ]

  # Appended to the chart's base conf (which always emits dir /data / port /
  # bind), so it is safe to add only the persistence directives here. Passed via
  # values, not set, because the value contains newlines that helm's --set
  # cannot express. save 60 1 snapshots within 60s of any change (Valkey's
  # built-in default is up to 1h - too lax for a low-write CAPTCHA); noeviction
  # matches the upstream quickstart.
  values = [
    yamlencode({
      valkeyConfig = "save 60 1\nmaxmemory-policy noeviction\n"
    }),
  ]
}
