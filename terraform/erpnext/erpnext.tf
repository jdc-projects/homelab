locals {
  erpnext_domain     = "erpnext.${var.server_base_domain}"
  erpnext_image_repo = "ghcr.io/jdc-projects/erpnext-extended"
  erpnext_image_tag  = "erpnext-v16.26.2-oidc-v0.4.0"
}

resource "helm_release" "erpnext" {
  name      = "erpnext"
  namespace = kubernetes_namespace.erpnext.metadata[0].name

  repository = "https://helm.erpnext.com"
  chart      = "erpnext"
  version    = "8.0.65"

  timeout       = 600
  wait_for_jobs = true

  values = [
    <<-EOT
      image:
        repository: "${local.erpnext_image_repo}"
        tag: "${local.erpnext_image_tag}"

      dbHost: "${kubernetes_manifest.erpnext_db.manifest.metadata.name}-primary"
      dbPort: 3306
      dbRootUser: "root"
      dbExistingSecret: "${kubernetes_secret.mariadb_root_password.metadata[0].name}"
      dbExistingSecretPasswordKey: "password"

      externalRedis:
        cache: "redis://${helm_release.valkey.name}:6379"
        queue: "redis://${helm_release.valkey.name}:6379"

      mariadb-sts:
        enabled: false
      mariadb-subchart:
        enabled: false
      mariadb:
        enabled: false
      postgresql:
        enabled: false
      postgresql-subchart:
        enabled: false
      valkey-cache:
        enabled: false
      valkey-queue:
        enabled: false
      redis-cache:
        enabled: false
      redis-queue:
        enabled: false
      dragonfly-cache:
        enabled: false
      dragonfly-queue:
        enabled: false

      jobs:
        createSite:
          enabled: true
          siteName: "${local.erpnext_domain}"
          adminExistingSecret: "${kubernetes_secret.erpnext_admin_password.metadata[0].name}"
          adminExistingSecretKey: "password"
          installApps:
            - "erpnext"
          dbType: "mariadb"

      persistence:
        worker:
          existingClaim: "${kubernetes_persistent_volume_claim.erpnext_sites.metadata[0].name}"

      worker:
        gunicorn:
          envVars:
            - name: FRAPPE_STREAM_LOGGING
              value: "1"
        scheduler:
          envVars:
            - name: FRAPPE_STREAM_LOGGING
              value: "1"
        default:
          envVars:
            - name: FRAPPE_STREAM_LOGGING
              value: "1"
        long:
          envVars:
            - name: FRAPPE_STREAM_LOGGING
              value: "1"
        short:
          envVars:
            - name: FRAPPE_STREAM_LOGGING
              value: "1"

      socketio:
        envVars:
          - name: FRAPPE_STREAM_LOGGING
            value: "1"

      ingress:
        enabled: false
    EOT
  ]
}

module "erpnext_ingress" {
  source = "../modules/ingress"

  name      = "erpnext"
  namespace = kubernetes_namespace.erpnext.metadata[0].name
  domain    = local.erpnext_domain

  target_port = 8080

  existing_service_name      = helm_release.erpnext.name
  existing_service_namespace = kubernetes_namespace.erpnext.metadata[0].name

  do_enable_crowdsec_bouncer_appsec = false
}
