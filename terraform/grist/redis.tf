resource "helm_release" "redis" {
  name      = "redis"
  namespace = kubernetes_namespace.grist.metadata[0].name

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  version    = "19.5.1"

  timeout = 300

  set {
    name  = "architecture"
    value = "standalone"
  }

  set_sensitive {
    name  = "auth.password"
    value = random_password.grist_redis_password.result
  }

  set {
    name  = "master.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.redis.metadata[0].name
  }
}
