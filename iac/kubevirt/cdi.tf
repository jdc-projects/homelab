resource "kubernetes_manifest" "cdi_instance" {
  manifest = {
    apiVersion = "cdi.kubevirt.io/v1beta1"
    kind       = "CDI"

    metadata = {
      name = "cdi"
    }

    spec = {
      config = {
        featureGates = [
          "HonorWaitForFirstConsumer",
        ]
        scratchSpaceStorageClass = "openebs-zfs-localpv-bulk-no-backup"
      }
      imagePullPolicy = "IfNotPresent"
      infra = {
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
          },
        ]
      }
      workload = {
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
      }
    }
  }
}

resource "null_resource" "cdi_readiness_check" {
  provisioner "local-exec" {
    command = <<-EOF
      kubectl wait cdi ${kubernetes_manifest.cdi_instance.manifest.metadata.name} --timeout 5m --for condition=Available
    EOF
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_manifest.cdi_instance
    ]
  }
}

resource "kubernetes_service" "cdi_uploadproxy_nodeport" {
  metadata {
    name      = "cdi-uploadproxy-nodeport"
    namespace = "cdi"

    labels = {
      "cdi.kubevirt.io" = "cdi-uploadproxy"
    }
  }

  spec {
    type = "NodePort"

    selector = {
      "cdi.kubevirt.io" = "cdi-uploadproxy"
    }

    port {
      port        = 443
      target_port = 8443
      node_port   = 31001
      protocol    = "TCP"
    }
  }
}

# CDI auto-creates StorageProfiles for every StorageClass but can't recognize
# OpenEBS provisioners (device.csi.openebs.io, openebs.io/local,
# zfs.csi.openebs.io), leaving all profiles incomplete/degraded. Configuring
# the spec explicitly tells CDI what each storage class supports so the
# profiles are marked complete and the CDIStorageProfilesIncomplete /
# CDIDefaultStorageClassDegraded alerts stop firing.
#
# These are applied via kubectl server-side apply (not kubernetes_manifest)
# because CDI's controller creates the StorageProfiles before OpenTofu runs.
# Server-side apply patches the spec fields without conflicting with CDI's
# status management. Works on both fresh deploys (after CDI creates the
# profiles) and existing clusters.
locals {
  cdi_storage_profile_names = [
    "openebs-zfs-localpv-bulk",
    "openebs-zfs-localpv-bulk-no-backup",
    "openebs-zfs-localpv-general",
    "openebs-zfs-localpv-general-no-backup",
    "openebs-zfs-localpv-random",
    "openebs-zfs-localpv-random-no-backup",
  ]
}

resource "terraform_data" "cdi_storage_profiles" {
  triggers_replace = [null_resource.cdi_readiness_check.id]

  provisioner "local-exec" {
    command = <<-EOF
      for sp in ${join(" ", local.cdi_storage_profile_names)}; do
        echo "Patching StorageProfile: $sp"
        kubectl patch storageprofile "$sp" --type=merge \
          -p '{"spec":{"cloneStrategy":"copy","claimPropertySets":[{"accessModes":["ReadWriteOnce"],"volumeMode":"Filesystem"}]}}' \
          || echo "WARNING: failed to patch $sp (may not exist yet)"
      done
    EOF
  }

  depends_on = [null_resource.cdi_readiness_check]
}
