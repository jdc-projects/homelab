resource "helm_release" "mariadb" {
  name      = "mariadb"
  namespace = kubernetes_namespace.seafile.metadata[0].name

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "mariadb"
  version    = "12.2.4"

  timeout = 300

  set {
    name  = "architecture"
    value = "standalone"
  }
  set {
    name  = "auth.rootPassword"
    value = random_password.mariadb_root_password.result
  }

  set {
    name  = "primary.persistence.enabled"
    value = "false" # TEMPORARY
  }
  set {
    name  = "primary.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.mariadb_primary.metadata[0].name
  }

  set {
    name  = "volumePermissions.enabled"
    value = "true"
  }
}