resource "kubernetes_config_map" "resource_policy" {
  metadata {
    name      = "resource-policy"
    namespace = kubernetes_namespace.velero.metadata[0].name
  }

  data = {
    "resource-policy.yaml" = <<-EOF
      version: v1
      volumePolicies:
      - conditions:
          storageClass:
          - truenas-nfs-csi-no-backup
        action:
          type: skip
    EOF
  }
}
