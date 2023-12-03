resource "kubernetes_job" "harbor_chown" {
  for_each = tomap({
    jobservice = tomap({
      claim_name = kubernetes_persistent_volume_claim.harbor["jobservice"].metadata[0].name
      chown_uid  = "10000"
      chown_gid  = "10000"
    })
    database = tomap({
      claim_name = kubernetes_persistent_volume_claim.harbor["database"].metadata[0].name
      chown_uid  = "999"
      chown_gid  = "999"
    })
    redis = tomap({
      claim_name = kubernetes_persistent_volume_claim.harbor["redis"].metadata[0].name
      chown_uid  = "999"
      chown_gid  = "999"
    })
    trivy = tomap({
      claim_name = kubernetes_persistent_volume_claim.harbor["trivy"].metadata[0].name
      chown_uid  = "10000"
      chown_gid  = "10000"
    })
  })

  metadata {
    name      = "harbor-${each.value.claim_name}-chown"
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.18.4"
          name  = "harbor-${each.value.claim_name}-chown"

          command = ["sh", "-c", "chown -R ${each.value.chown_uid}:${each.value.chown_gid} /chown"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/chown"
            name       = "chown-harbor-${each.value.claim_name}-data"
          }
        }

        volume {
          name = "chown-harbor-${each.value.claim_name}-data"

          persistent_volume_claim {
            claim_name = each.value.claim_name
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 0
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

resource "helm_release" "harbor" {
  name = "harbor"

  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  version    = "1.13.1"

  namespace = kubernetes_namespace.harbor.metadata[0].name

  timeout = 600

  set {
    name  = "expose.type"
    value = "ingress"
  }
  set {
    name  = "expose.tls.enabled"
    value = "false"
  }

  set {
    name  = "expose.ingress.hosts.core"
    value = "harbor.${var.server_base_domain}"
  }
  set {
    name  = "expose.ingress.annotations"
    value = "null"
  }

  set {
    name  = "externalURL"
    value = "https://harbor.${var.server_base_domain}"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.persistentVolumeClaim.jobservice.joblog.existingClaim"
    value = kubernetes_persistent_volume_claim.harbor["jobservice"].metadata[0].name
  }
  set {
    name  = "persistence.persistentVolumeClaim.jobservice.joblog.size"
    value = kubernetes_persistent_volume_claim.harbor["jobservice"].spec[0].resources[0].requests.storage
  }
  set {
    name  = "persistence.persistentVolumeClaim.database.existingClaim"
    value = kubernetes_persistent_volume_claim.harbor["database"].metadata[0].name
  }
  set {
    name  = "persistence.persistentVolumeClaim.database.size"
    value = kubernetes_persistent_volume_claim.harbor["database"].spec[0].resources[0].requests.storage
  }
  set {
    name  = "persistence.persistentVolumeClaim.redis.existingClaim"
    value = kubernetes_persistent_volume_claim.harbor["redis"].metadata[0].name
  }
  set {
    name  = "persistence.persistentVolumeClaim.redis.size"
    value = kubernetes_persistent_volume_claim.harbor["redis"].spec[0].resources[0].requests.storage
  }
  set {
    name  = "persistence.persistentVolumeClaim.trivy.existingClaim"
    value = kubernetes_persistent_volume_claim.harbor["trivy"].metadata[0].name
  }
  set {
    name  = "persistence.persistentVolumeClaim.trivy.size"
    value = kubernetes_persistent_volume_claim.harbor["trivy"].spec[0].resources[0].requests.storage
  }

  set {
    name  = "persistence.imageChartStorage.disableredirect"
    value = "true"
  }
  set {
    name  = "persistence.imageChartStorage.type"
    value = "s3"
  }
  set {
    name  = "persistence.imageChartStorage.s3.region"
    value = "us-east-1"
  }
  set {
    name  = "persistence.imageChartStorage.s3.bucket"
    value = "harbor"
  }
  set {
    name  = "persistence.imageChartStorage.s3.accesskey"
    value = random_password.minio_access_key.result
  }
  set {
    name  = "persistence.imageChartStorage.s3.secretkey"
    value = random_password.minio_secret_key.result
  }
  set {
    name  = "persistence.imageChartStorage.s3.regionendpoint"
    value = "http://${helm_release.minio.name}:9000"
  }
  set {
    name  = "persistence.imageChartStorage.s3.encrypt"
    value = "false"
  }
  set {
    name  = "persistence.imageChartStorage.s3.secure"
    value = "false"
  }
  set {
    name  = "persistence.imageChartStorage.s3.skipverify"
    value = "false"
  }
  set {
    name  = "persistence.imageChartStorage.s3.v4auth"
    value = "true"
  }

  set_sensitive {
    name  = "core.secret"
    value = random_password.harbor_core_secret.result
  }
  set_sensitive {
    name  = "jobservice.secret"
    value = random_password.harbor_jobservice_secret.result
  }
  set_sensitive {
    name  = "registry.secret"
    value = random_password.harbor_registry_secret.result
  }

  set_sensitive {
    name  = "harborAdminPassword"
    value = random_password.harbor_admin_password.result
  }

  set_sensitive {
    name  = "secretKey"
    value = random_password.harbor_secret_key.result
  }

  depends_on = [
    helm_release.minio,
    kubernetes_job.harbor_chown
  ]
}
