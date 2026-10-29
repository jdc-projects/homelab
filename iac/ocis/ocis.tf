resource "null_resource" "ocis_helm_repo_clone" {
  triggers = {
    always_run = timestamp()
    # The owncloud/ocis-charts repo does not publish versioned releases, so we
    # pin to a commit on `main` and bump deliberately. This pin is chart 0.8.0
    # (appVersion 8.2.0): the 8.x app baseline, the storage-users
    # clean-expired-uploads CronJob NATS fix, and optional (off by default)
    # MFA/Vault chart support. Note the 0.7 -> 0.8 jump also upgrades the ocis
    # app itself 7.1.4 -> 8.2.0. Get the latest SHA from:
    # https://github.com/owncloud/ocis-charts/commits/main/
    commit_sha = "36a4490a94c033c610fcda0de7a62d25206bff02"
  }

  provisioner "local-exec" {
    command = <<-EOF
      mkdir ./ocis-charts
      cd ./ocis-charts
      git init
      git remote add origin https://github.com/owncloud/ocis-charts.git
      git fetch origin ${self.triggers.commit_sha}
      git reset --hard FETCH_HEAD
    EOF
  }
}

locals {
  ocis_domain = "files.${var.server_base_domain}"
}

resource "helm_release" "ocis" {
  name  = "ocis"
  chart = "./ocis-charts/charts/ocis"

  namespace = kubernetes_namespace.ocis.metadata[0].name

  timeout = 600

  set = [
    {
      name  = "logging.level"
      value = "info"
    },
    {
      name  = "logging.color"
      value = "false"
    },
    {
      name  = "logging.pretty"
      value = "false"
    },

    {
      name  = "externalDomain"
      value = local.ocis_domain
    },

    {
      name  = "cache.type"
      value = "noop"
    },

    {
      name  = "features.emailNotifications.enabled"
      value = "true"
    },
    {
      name  = "features.emailNotifications.smtp.host"
      value = var.smtp_host
    },
    {
      name  = "features.emailNotifications.smtp.port"
      value = var.smtp_port
    },
    {
      name  = "features.emailNotifications.smtp.sender"
      value = "noreply@${var.server_base_domain}"
    },
    {
      name  = "features.emailNotifications.smtp.authentication"
      value = "login"
    },
    {
      name  = "features.emailNotifications.smtp.encryption"
      value = "tls"
    },

    {
      name  = "features.sharing.publiclink.writeableShareMustHavePassword"
      value = "true"
    },

    {
      name  = "features.externalUserManagement.enabled"
      value = "true"
    },
    {
      name  = "features.externalUserManagement.oidc.issuerURI"
      value = data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url
    },
    {
      name  = "features.externalUserManagement.oidc.sessionManagementLink"
      value = "${data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url}/account/"
    },
    {
      name  = "features.externalUserManagement.oidc.editAccountLink"
      value = "${data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url}/account/"
    },
    {
      name  = "features.externalUserManagement.oidc.userIDClaim"
      value = "preferred_username"
    },
    {
      name  = "features.externalUserManagement.oidc.userIDClaimAttributeMapping"
      value = "userid"
    },
    {
      name  = "features.externalUserManagement.oidc.accessTokenVerifyMethod"
      value = "jwt"
    },
    {
      # Validate tokens locally (JWKS) and read claims - including the `roles`
      # role-assignment claim, which the Keycloak mapper adds to the access
      # token (see keycloak-roles.tf) - without a per-request call to
      # Keycloak's userinfo endpoint. That call left the cluster via the
      # public URL (pod -> Cloudflare -> Traefik -> crowdsec bouncer ->
      # Keycloak), making OCIS auth hostage to edge health: when appsec
      # fail-closed during file uploads (2026-10-29), every authenticated
      # OCIS request 401'd. Trade-off: role changes apply at the next token
      # refresh instead of the next request.
      name  = "features.externalUserManagement.oidc.skipUserInfo"
      value = "true"
    },
    {
      name  = "features.externalUserManagement.oidc.roleAssignment.enabled"
      value = "true"
    },
    {
      name  = "features.externalUserManagement.oidc.roleAssignment.claim"
      value = "roles"
    },

    {
      name  = "features.externalUserManagement.ldap.writeable"
      value = "false"
    },
    {
      name  = "features.externalUserManagement.ldap.uri"
      value = "ldaps://idm.${var.server_base_domain}"
    },
    {
      name  = "features.externalUserManagement.ldap.bindDN"
      value = "uid=${data.terraform_remote_state.openldap.outputs.admin_username}\\,ou=people\\,dc=idm\\,dc=homelab"
    },
    {
      name  = "features.externalUserManagement.ldap.useServerUUID"
      value = "true"
    },
    {
      name  = "features.externalUserManagement.ldap.user.schema.id"
      value = "uid"
    },
    {
      name  = "features.externalUserManagement.ldap.user.baseDN"
      value = "ou=people\\,dc=idm\\,dc=homelab"
    },
    {
      name  = "features.externalUserManagement.ldap.group.schema.id"
      value = "cn"
    },
    {
      name  = "features.externalUserManagement.ldap.group.schema.member"
      value = "member"
    },
    {
      name  = "features.externalUserManagement.ldap.group.baseDN"
      value = "ou=groups\\,dc=idm\\,dc=homelab"
    },
    {
      name  = "features.externalUserManagement.ldap.group.objectClass"
      value = "groupOfNames"
    },
    {
      name  = "features.externalUserManagement.ldap.disableUsers.disableMechanism"
      value = "group"
    },
    {
      name  = "features.externalUserManagement.ldap.disableUsers.disabledUsersGroupDN"
      value = "cn=app_disabled\\,ou=groups\\,dc=idm\\,dc=homelab"
    },

    {
      name  = "ingress.enabled"
      value = "false"
    },

    {
      name  = "configRefs.storageusersConfigRef"
      value = kubernetes_config_map.storage_users.metadata[0].name
    },
    {
      name  = "configRefs.graphConfigRef"
      value = kubernetes_config_map.graph.metadata[0].name
    },

    {
      name  = "secretRefs.jwtSecretRef"
      value = kubernetes_secret.jwt_secret.metadata[0].name
    },
    {
      name  = "secretRefs.ldapSecretRef"
      value = kubernetes_secret.ldap_bind_secrets.metadata[0].name
    },
    {
      name  = "secretRefs.machineAuthApiKeySecretRef"
      value = kubernetes_secret.machine_auth_api_key.metadata[0].name
    },
    {
      name  = "secretRefs.notificationsSmtpSecretRef"
      value = kubernetes_secret.notifications_smtp_secret.metadata[0].name
    },
    {
      name  = "secretRefs.storagesystemJwtSecretRef"
      value = kubernetes_secret.storage_system_jwt_secret.metadata[0].name
    },
    {
      name  = "secretRefs.storagesystemSecretRef"
      value = kubernetes_secret.storage_system.metadata[0].name
    },
    {
      name  = "secretRefs.thumbnailsSecretRef"
      value = kubernetes_secret.thumbnails_transfer_secret.metadata[0].name
    },
    {
      name  = "secretRefs.transferSecretSecretRef"
      value = kubernetes_secret.transfer_secret.metadata[0].name
    },

    {
      name  = "services.nats.persistence.enabled"
      value = "true"
    },
    {
      name  = "services.nats.persistence.chownInitContainer"
      value = "true"
    },
    {
      name  = "services.nats.persistence.existingClaim"
      value = kubernetes_persistent_volume_claim.ocis["nats"].metadata[0].name
    },

    {
      name  = "services.search.persistence.enabled"
      value = "true"
    },
    {
      name  = "services.search.persistence.chownInitContainer"
      value = "true"
    },
    {
      name  = "services.search.persistence.existingClaim"
      value = kubernetes_persistent_volume_claim.ocis["search"].metadata[0].name
    },

    {
      name  = "services.storagesystem.persistence.enabled"
      value = "true"
    },
    {
      name  = "services.storagesystem.persistence.chownInitContainer"
      value = "true"
    },
    {
      name  = "services.storagesystem.persistence.existingClaim"
      value = kubernetes_persistent_volume_claim.ocis["storagesystem"].metadata[0].name
    },

    {
      name  = "services.storageusers.persistence.enabled"
      value = "true"
    },
    {
      name  = "services.storageusers.persistence.chownInitContainer"
      value = "true"
    },
    {
      name  = "services.storageusers.persistence.existingClaim"
      value = kubernetes_persistent_volume_claim.ocis["storageusers"].metadata[0].name
    },

    {
      name  = "services.thumbnails.persistence.enabled"
      value = "true"
    },
    {
      name  = "services.thumbnails.persistence.chownInitContainer"
      value = "true"
    },
    {
      name  = "services.thumbnails.persistence.existingClaim"
      value = kubernetes_persistent_volume_claim.ocis["thumbnails"].metadata[0].name
    },

    {
      name  = "services.web.config.oidc.webClientID"
      value = keycloak_openid_client.ocis_web.client_id
    },
    {
      name  = "services.web.persistence.enabled"
      value = "true"
    },
    {
      name  = "services.web.persistence.chownInitContainer"
      value = "true"
    },
    {
      name  = "services.web.persistence.existingClaim"
      value = kubernetes_persistent_volume_claim.ocis["web"].metadata[0].name
    },
  ]

  depends_on = [null_resource.ocis_helm_repo_clone]

  lifecycle {
    replace_triggered_by = [null_resource.ocis_helm_repo_clone]
  }
}

module "ocis_ingress" {
  source = "../modules/ingress"

  name      = "ocis"
  namespace = kubernetes_namespace.ocis.metadata[0].name
  domain    = local.ocis_domain

  target_port = 9200

  existing_service_name      = "proxy"
  existing_service_namespace = helm_release.ocis.namespace
}
