resource "kubernetes_secret" "ocis_ldap_password_secret" {
  metadata {
    name      = "ocis-ldap-password"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
    reva-ldap-bind-password = var.lldap_admin_password
  }
}

resource "helm_release" "ocis" {
  name  = "ocis"
  chart = "./ocis-charts/charts/ocis"

  namespace = kubernetes_namespace.ocis_namespace.metadata[0].name

  timeout = 300

  set {
    name  = "logging.level"
    value = "debug"
  }

  set {
    name  = "externalDomain"
    value = "ocis.${var.server_base_domain}"
  }

  set {
    name  = "features.externalUserManagement.enabled"
    value = "true"
  }
  set { # ***** TEMPORARY *****
    name  = "features.externalUserManagement.ldap.adminUUID"
    value = "e25b0b56-6478-4a95-b8be-f5cd1636d2a9"
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
    value = "${data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id}.user.uuid"
  }
  set {
    name  = "features.externalUserManagement.oidc.userIDClaimAttributeMapping"
    value = "userID"
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
  # set {
  #   name  = "features.externalUserManagement.ldap.useServerUUID"
  #   value = "true"
  # }
  # ***** user schema options need to be filled out
  # set {
  #   name  = "features.externalUserManagement.ldap.useServerUUID"
  #   value = ""
  # }
  # *****
  set {
    name  = "features.externalUserManagement.ldap.user.baseDN"
    value = "ou=people,dc=idm,dc=${var.server_base_domain}"
  }
  # ***** group schema options nee to be filled out
  # set {
  #   name  = "features.externalUserManagement.ldap.useServerUUID"
  #   value = ""
  # }
  # *****
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
}
