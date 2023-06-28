resource "kubernetes_secret" "ocis_ldap_password_secret" {
  metadata {
    name      = "ocis-ldap-password"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
    reva-ldap-bind-password = var.lldap_admin_password
  }
}

resource "random_password" "jwt_secret" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "ocis_jwt_secret" {
  metadata {
    name      = "ocis-jwt-secret"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
    jwt-secret = random_password.jwt_secret.result
  }
}

resource "helm_release" "ocis" {
  name  = "ocis"
  chart = "./ocis-charts/charts/ocis"

  namespace = kubernetes_namespace.ocis_namespace.metadata[0].name

  timeout = 300

  set {
    name  = "logging.level"
    value = "info"
  }

  set {
    name  = "externalDomain"
    value = "ocis.${var.server_base_domain}"
  }

  set {
    name  = "secretRefs.jwtSecretRef"
    value = kubernetes_secret.ocis_jwt_secret.metadata[0].name
  }

  set {
    name  = "features.externalUserManagement.enabled"
    value = "true"
  }
  set { # ***** TEMPORARY *****
    name  = "features.externalUserManagement.ldap.adminUUID"
    value = "jack"
  }
  set {
    name  = "features.externalUserManagement.oidc.issuerURI"
    value = "https://idp.${var.server_base_domain}/realms/${data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id}"
  }
  set {
    name  = "features.externalUserManagement.oidc.webClientID"
    value = keycloak_openid_client.ocis_web_client.client_id
  }
  set {
    name  = "features.externalUserManagement.oidc.userIDClaim"
    value = "${data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id}.user.username"
  }
  set {
    name  = "features.externalUserManagement.oidc.userIDClaimAttributeMapping"
    value = "username"
  }
  # set {
  #   name  = "features.externalUserManagement.oidc.roleAssignment.enabled"
  #   value = "true"
  # }

  set {
    name  = "features.externalUserManagement.ldap.writeable"
    value = "false"
  }
  set {
    name  = "features.externalUserManagement.ldap.uri"
    value = "ldaps://idm.${var.server_base_domain}"
  }
  set {
    name  = "features.externalUserManagement.ldap.bindDN"
    value = "uid=admin,ou=people,dc=idm,dc=${var.server_base_domain}"
  }
  set {
    name  = "secretRefs.ldapSecretRef"
    value = kubernetes_secret.ocis_ldap_password_secret.metadata[0].name
  }
  set {
    name  = "features.externalUserManagement.ldap.passwordModifyExOpEnabled"
    value = "true"
  }
  set {
    name  = "features.externalUserManagement.ldap.useServerUUID"
    value = "true"
  }
  set {
    name  = "features.externalUserManagement.ldap.user.schema.id"
    value = "uid"
  }
  set {
    name  = "features.externalUserManagement.ldap.user.schema.filter"
    value = "(&(objectClass=person)(memberOf=uid=ocis,ou=groups,dc=idm,dc=${var.server_base_domain}))"
  }
  set {
    name  = "features.externalUserManagement.ldap.user.schema.objectClass"
    value = "person"
  }
  set {
    name  = "features.externalUserManagement.ldap.group.schema.id"
    value = "uid"
  }
  set {
    name  = "features.externalUserManagement.ldap.group.baseDN"
    value = "ou=groups,dc=idm,dc=${var.server_base_domain}"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
    value = "websecure"
  }

  set {
    name  = "services.storageusers.storageBackend.persistence.enabled"
    value = "false" # ***** CHANGE THIS LATER *****
  }
  set {
    name  = "services.storageusers.storageBackend.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_storageusers_pvc.metadata[0].name
  }

  set {
    name  = "services.store.persistence.enabled"
    value = "false" # ***** CHANGE THIS LATER *****
  }
  set {
    name  = "services.store.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_store_pvc.metadata[0].name
  }

  set {
    name  = "services.web.persistence.enabled"
    value = "false" # ***** CHANGE THIS LATER *****
  }

  depends_on = [null_resource.ocis_helm_repo]

  lifecycle {
    replace_triggered_by = [
      kubernetes_secret.ocis_ldap_password_secret,
      kubernetes_secret.ocis_jwt_secret,
      null_resource.ocis_helm_repo # ***** temporary for debug - will for replace each time *****
    ]
  }
}
