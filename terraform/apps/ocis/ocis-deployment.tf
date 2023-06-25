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

  # set {
  #   name  = "features.externalUserManagement.enabled"
  #   value = "true"
  # }
  # set {
  #   name  = "features.externalUserManagement.enabled"
  #   value = ""
  # }
  # set {
  #   name  = "features.externalUserManagement.enabled"
  #   value = ""
  # }
  # set {
  #   name  = "features.externalUserManagement.enabled"
  #   value = ""
  # }
  # set {
  #   name  = "features.externalUserManagement.enabled"
  #   value = ""
  # }
  # set {
  #   name  = "features.externalUserManagement.enabled"
  #   value = ""
  # }

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
