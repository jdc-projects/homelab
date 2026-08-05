resource "kubernetes_secret" "notifications_smtp_secret" {
  metadata {
    name      = "notifications-smtp-secret"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    smtp-username = var.smtp_username
    smtp-password = var.smtp_password
  }
}

resource "kubernetes_secret" "ldap_bind_secrets" {
  metadata {
    name      = "ldap-bind-secrets"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    reva-ldap-bind-password = data.terraform_remote_state.openldap.outputs.admin_password
  }
}

resource "kubernetes_secret" "jwt_secret" {
  metadata {
    name      = "jwt-secret"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    jwt-secret = random_password.jwt_secret.result
  }
}

resource "kubernetes_secret" "machine_auth_api_key" {
  metadata {
    name      = "machine-auth-api-key"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    machine-auth-api-key = random_password.machine_auth_api_key.result
  }
}

resource "kubernetes_secret" "storage_system" {
  metadata {
    name      = "storage-system"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    user-id = random_uuid.storage_system_user_id.result
    api-key = random_password.storage_system_api_key.result
  }
}

resource "kubernetes_secret" "storage_system_jwt_secret" {
  metadata {
    name      = "storage-system-jwt-secret"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    storage-system-jwt-secret = random_password.storage_system_jwt_secret.result
  }
}

resource "kubernetes_secret" "transfer_secret" {
  metadata {
    name      = "transfer-secret"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    transfer-secret = random_password.transfer_secret.result
  }
}

resource "kubernetes_secret" "thumbnails_transfer_secret" {
  metadata {
    name      = "thumbnails-transfer-secret"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    thumbnails-transfer-secret = random_password.thumbnails_transfer_secret.result
  }
}
