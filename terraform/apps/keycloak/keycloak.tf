resource "null_resource" "keycloak_domain" {
  triggers = {
    keycloak_domain = "idp.${var.server_base_domain}"
  }
}

resource "kubernetes_config_map" "keycloak_extra_env_vars" {
  metadata {
    name      = "keycloak-extra-env-vars"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  data = {
    KC_FEATURES = "scripts"
  }
}

data "archive_file" "keycloak_scripts_jar" {
  type        = "zip"
  output_path = "./scripts.jar"
  source_dir  = "./scripts"
  output_file_mode = "0444"
}

resource "kubernetes_config_map" "keycloak_custom_scripts" {
  metadata {
    name      = "keycloak-custom-scripts"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  binary_data = {
    "scripts.jar" = "${filebase64("${data.archive_file.keycloak_scripts_jar.output_path}")}"
  }

  depends_on = [data.archive_file.keycloak_scripts_jar]
}

resource "helm_release" "keycloak" {
  name      = "keycloak"
  namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "keycloak"
  version    = "15.1.6"

  timeout = 300

  set {
    name  = "auth.adminUser"
    value = random_password.keycloak_admin_username.result
  }
  set {
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
    name  = "extraVolumeMounts[0].name"
    value = "scripts-jar"
  }
  set {
    name  = "extraVolumeMounts[0].mountPath"
    value = "/opt/bitnami/keycloak/providers"
  }
  set {
    name  = "extraVolumeMounts[0].readOnly"
    value = "true"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.hostname"
    value = null_resource.keycloak_domain.triggers.keycloak_domain
  }
  set {
    name  = "ingress.servicePort"
    value = "https"
  }

  set {
    name  = "postgres.auth.postgresPassword"
    value = random_password.db_admin_password.result
  }
}

resource "null_resource" "keycloak_liveness_check" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "timeout 300 bash -c 'while ! curl -sfI https://${null_resource.keycloak_domain.triggers.keycloak_domain}; do echo \"Waiting for Keycloak to be live.\" && sleep 1; done'"
  }

  depends_on = [helm_release.keycloak]
}
