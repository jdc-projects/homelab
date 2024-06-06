resource "kubernetes_config_map" "keycloak_extra_env_vars" {
  metadata {
    name      = "keycloak-extra-env-vars"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    KC_FEATURES = "scripts"
  }
}

resource "helm_release" "keycloak" {
  name      = "keycloak"
  namespace = kubernetes_namespace.keycloak.metadata[0].name

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "keycloak"
  version    = "21.4.0"

  timeout = 300

  set_sensitive {
    name  = "auth.adminUser"
    value = random_password.keycloak_admin_username.result
  }
  set_sensitive {
    name  = "auth.adminPassword"
    value = random_password.keycloak_admin_password.result
  }

  set {
    name  = "tls.enabled"
    value = "true"
  }
  set {
    name  = "tls.autoGenerated"
    value = "true"
  }

  set {
    name  = "production"
    value = "true"
  }

  set {
    name  = "proxy"
    value = "reencrypt"
  }

  set {
    name  = "extraEnvVarsCM"
    value = kubernetes_config_map.keycloak_extra_env_vars.metadata[0].name
  }

  set {
    name  = "service.http.enabled"
    value = "false"
  }

  set {
    name  = "extraVolumes[0].name"
    value = "scripts-jar"
  }
  set {
    name  = "extraVolumes[0].configMap.name"
    value = kubernetes_config_map.keycloak_custom_scripts.metadata[0].name
  }
  set {
    name  = "extraVolumes[0].readOnly"
    value = "true"
  }
  set {
    name  = "extraVolumeMounts[0].name"
    value = "scripts-jar"
  }
  set {
    name  = "extraVolumeMounts[0].mountPath"
    value = "/opt/bitnami/keycloak/providers"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.hostname"
    value = data.terraform_remote_state.prometheus_operator.outputs.oauth_domain
  }
  set {
    name  = "ingress.servicePort"
    value = "https"
  }
  set {
    name  = "ingress.annotations"
    value = "traefik.ingress.kubernetes.io/router.entrypoints: websecure"
  }

  set {
    name  = "postgresql.enabled"
    value = "false"
  }

  set {
    name  = "externalDatabase.host"
    value = "${kubernetes_manifest.keycloak_db.manifest.metadata.name}-rw"
  }
  set {
    name  = "externalDatabase.port"
    value = "5432"
  }
  set_sensitive {
    name  = "externalDatabase.user"
    value = random_password.keycloak_db_username.result
  }
  set {
    name  = "externalDatabase.database"
    value = kubernetes_manifest.keycloak_db.manifest.spec.bootstrap.initdb.database
  }
  set_sensitive {
    name  = "externalDatabase.password"
    value = random_password.keycloak_db_password.result
  }

  set {
    name  = "logging.level"
    value = "INFO"
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.keycloak_custom_scripts,
    ]
  }
}

resource "null_resource" "keycloak_liveness_check" {
  provisioner "local-exec" {
    command = "timeout 300 bash -c 'while ! curl -sfI https://${data.terraform_remote_state.prometheus_operator.outputs.oauth_domain}; do echo \"Waiting for Keycloak to be live.\" && sleep 1; done'"
  }

  depends_on = [helm_release.keycloak]

  lifecycle {
    replace_triggered_by = [
      helm_release.keycloak
    ]
  }
}
