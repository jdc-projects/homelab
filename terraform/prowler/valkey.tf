resource "helm_release" "valkey" {
  name      = "valkey"
  namespace = kubernetes_namespace.prowler.metadata[0].name

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "valkey"
  version    = "2.4.6"

  timeout = 300

  set {
    name  = "architecture"
    value = "standalone"
  }

  set_sensitive {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "primary.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.valkey.metadata[0].name
  }
}
