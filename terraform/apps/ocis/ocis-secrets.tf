resource "kubernetes_secret" "ocis_external_user_management" {
  metadata {
    name      = "ocis-external-user-management"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    reva-ldap-bind-password = data.terraform_remote_state.openldap.outputs.admin_password
  }
}

resource "kubernetes_secret" "ocis_jwt" {
  metadata {
    name      = "ocis-jwt"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    jwt-secret = random_password.jwt_secret.result
  }
}

resource "kubernetes_secret" "ocis_machine_auth_api_key" {
  metadata {
    name      = "ocis-machine-auth-api-key"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    machine-auth-api-key = random_password.machine_auth_api_key.result
  }
}

resource "kubernetes_secret" "ocis_storage_system" {
  metadata {
    name      = "ocis-storage-system"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    user-id = random_uuid.storage_system_user_id.result
    api-key = random_password.storage_system_api_key.result
  }
}

resource "kubernetes_secret" "ocis_storage_system_jwt" {
  metadata {
    name      = "ocis-storage-system-jwt"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    storage-system-jwt-secret = random_password.storage_system_jwt_secret.result
  }
}

resource "kubernetes_secret" "ocis_transfer" {
  metadata {
    name      = "ocis-transfer"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    transfer-secret = random_password.transfer_secret.result
  }
}

resource "kubernetes_secret" "ocis_thumbnails_transfer" {
  metadata {
    name      = "ocis-thumbnails-transfer"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    thumbnails-transfer-secret = random_password.thumbnails_transfer_secret.result
  }
}

resource "kubernetes_secret" "ocis_notifications_smtp" {
  metadata {
    name      = "ocis-thumbnails-transfer"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    smtp-username = var.smtp_username
    smtp-password = var.smtp_password
  }
}
