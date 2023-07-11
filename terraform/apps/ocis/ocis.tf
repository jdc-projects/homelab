resource "helm_release" "ocis" {
  name  = "ocis"
  chart = "./ocis-charts/charts/ocis"

  namespace = kubernetes_namespace.ocis.metadata[0].name

  timeout = 300

  set {
    name  = "logging.level"
    value = "trace"
  }
  set {
    name  = "logging.color"
    value = "true"
  }
  set {
    name  = "logging.pretty"
    value = "true"
  }

  set {
    name  = "externalDomain"
    value = "ocis.${var.server_base_domain}"
  }

  set {
    name  = "secretRefs.jwtSecretRef"
    value = kubernetes_secret.ocis_jwt.metadata[0].name
  }
  set {
    name  = "secretRefs.ldapSecretRef"
    value = kubernetes_secret.ocis_external_user_management.metadata[0].name
  }
  set {
    name  = "secretRefs.machineAuthApiKeySecretRef"
    value = kubernetes_secret.ocis_machine_auth_api_key.metadata[0].name
  }
  set {
    name  = "secretRefs.storagesystemJwtSecretRef"
    value = kubernetes_secret.ocis_storage_system_jwt.metadata[0].name
  }
  set {
    name  = "secretRefs.storagesystemSecretRef"
    value = kubernetes_secret.ocis_storage_system.metadata[0].name
  }
  set {
    name  = "secretRefs.thumbnailsSecretRef"
    value = kubernetes_secret.ocis_thumbnails_transfer.metadata[0].name
  }
  set {
    name  = "secretRefs.transferSecretSecretRef"
    value = kubernetes_secret.ocis_transfer.metadata[0].name
  }

  set {
    name  = "services.nats.persistence.enabled"
    value = "true"
  }
  set {
    name  = "services.nats.persistence.chownInitContainer"
    value = "true"
  }
  set {
    name  = "services.nats.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_nats_pvc.metadata[0].name
  }

  set {
    name  = "services.search.persistence.enabled"
    value = "true"
  }
  set {
    name  = "services.search.persistence.chownInitContainer"
    value = "true"
  }
  set {
    name  = "services.search.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_search_pvc.metadata[0].name
  }

  set {
    name  = "services.storagesystem.persistence.enabled"
    value = "true"
  }
  set {
    name  = "services.storagesystem.persistence.chownInitContainer"
    value = "true"
  }
  set {
    name  = "services.storagesystem.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_storagesystem_pvc.metadata[0].name
  }

  set {
    name  = "services.storageusers.persistence.enabled"
    value = "true"
  }
  set {
    name  = "services.storageusers.persistence.chownInitContainer"
    value = "true"
  }
  set {
    name  = "services.storageusers.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_storageusers_pvc.metadata[0].name
  }

  set {
    name  = "services.store.persistence.enabled"
    value = "true"
  }
  set {
    name  = "services.store.persistence.chownInitContainer"
    value = "true"
  }
  set {
    name  = "services.store.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_store_pvc.metadata[0].name
  }

  set {
    name  = "services.thumbnails.persistence.enabled"
    value = "true"
  }
  set {
    name  = "services.thumbnails.persistence.chownInitContainer"
    value = "true"
  }
  set {
    name  = "services.thumbnails.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_thumbnails_pvc.metadata[0].name
  }

  set {
    name  = "services.web.persistence.enabled"
    value = "true"
  }
  set {
    name  = "services.web.persistence.chownInitContainer"
    value = "true"
  }
  set {
    name  = "services.web.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.ocis_web_pvc.metadata[0].name
  }

  set {
    name  = "features.externalUserManagement.enabled"
    value = "true"
  }
  set {
    name  = "features.externalUserManagement.oidc.issuerURI"
    value = "${data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url}/realms/${data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id}"
  }
  set {
    name  = "features.externalUserManagement.oidc.webClientID"
    value = keycloak_openid_client.ocis_web.client_id
  }
  set {
    name  = "features.externalUserManagement.oidc.userIDClaim"
    value = "preferred_username"
  }
  set {
    name  = "features.externalUserManagement.oidc.userIDClaimAttributeMapping"
    value = "userid"
  }
  set {
    name  = "features.externalUserManagement.oidc.accessTokenVerifyMethod"
    value = "jwt"
  }
  set {
    name  = "features.externalUserManagement.oidc.roleAssignment.enabled"
    value = "true"
  }
  set {
    name  = "features.externalUserManagement.oidc.roleAssignment.claim"
    value = "roles"
  }

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
    value = "uid=${data.terraform_remote_state.openldap.outputs.admin_username}\\,ou=people\\,dc=idm\\,dc=${var.server_base_domain}"
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
    name  = "features.externalUserManagement.ldap.user.baseDN"
    value = "ou=people\\,dc=idm\\,dc=${var.server_base_domain}"
  }
  set {
    name  = "features.externalUserManagement.ldap.group.schema.id"
    value = "cn"
  }
  set {
    name  = "features.externalUserManagement.ldap.group.schema.member"
    value = "member"
  }
  set {
    name  = "features.externalUserManagement.ldap.group.baseDN"
    value = "ou=groups\\,dc=idm\\,dc=${var.server_base_domain}"
  }
  set {
    name  = "features.externalUserManagement.ldap.group.objectClass"
    value = "groupOfNames"
  }
  set {
    name  = "features.externalUserManagement.ldap.disableUsers.disableMechanism"
    value = "group"
  }
  set {
    name  = "features.externalUserManagement.ldap.disableUsers.disabledUsersGroupDN"
    value = "cn=app_disabled\\,ou=groups\\,dc=idm\\,dc=${var.server_base_domain}"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
    value = "websecure"
  }

  depends_on = [null_resource.ocis_helm_repo_clone]

  lifecycle {
    replace_triggered_by = [null_resource.ocis_helm_repo_clone]
  }
}
