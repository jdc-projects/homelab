resource "helm_release" "supabase" {
  name      = "supabase"
  namespace = kubernetes_namespace.supabase.metadata[0].name

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "supabase"
  version    = "2.11.0"

  timeout = 120

  set_sensitive {
    name  = "jwt.secret"
    value = random_password.jwt_secret.result
  }
  set_sensitive {
    name  = "jwt.anonKey"
    value = jwt_hashed_token.anon_key.token
  }
  set_sensitive {
    name  = "jwt.serviceKey"
    value = jwt_hashed_token.service_key.token
  }

  set {
    name  = "publicURL"
    value = "https://supabase.${var.server_base_domain}"
  }

  # set {
  #   name  = "storage.persistence.existingClaim"
  #   value = ""
  # }
  # ***** temporary, wont be needed once existingClaim is used
  set {
    name  = "storage.persistence.storageClass"
    value = "openebs-zfs-localpv-general"
  }

  set {
    name  = "studio.publicURL"
    value = "https://studio.${var.server_base_domain}"
  }
  # ***** ingress should be handled externally so I can add some auth
  set {
    name  = "studio.ingress.enabled"
    value = "true"
  }
  set {
    name  = "studio.ingress.hostname"
    value = "studio.${var.server_base_domain}"
  }

  set {
    name  = "kong.ingress.enabled"
    value = "true"
  }
  set {
    name  = "kong.ingress.hostname"
    value = "supabase.${var.server_base_domain}"
  }

  # **** temporary, won't be needed once using external PG
  # set {
  #   name  = "postgresql.primary.persistence.storageClass"
  #   value = "openebs-zfs-localpv-random"
  # }

  # ***** don't exist anymore, so how do I provide these??
  # set_sensitive {
  #   name  = "auth.adminUser"
  #   value = random_password.supabase_admin_username.result
  # }
  # set_sensitive {
  #   name  = "auth.adminPassword"
  #   value = random_password.supabase_admin_password.result
  # }

  # set {
  #   name  = "PLACEHOLDER.ingress.annotations"
  #   value = "traefik.ingress.kubernetes.io/router.entrypoints: websecure"
  # }

  set {
    name  = "postgresql.enabled"
    value = "false"
  }

  set {
    name  = "externalDatabase.host"
    value = "${kubernetes_manifest.supabase_db.manifest.metadata.name}-rw"
  }
  set {
    name  = "externalDatabase.port"
    value = "5432"
  }
  set_sensitive {
    name  = "externalDatabase.user"
    value = random_password.supabase_db_username.result
  }
  set {
    name  = "externalDatabase.database"
    value = kubernetes_manifest.supabase_db.manifest.spec.bootstrap.initdb.database
  }
  set_sensitive {
    name  = "externalDatabase.password"
    value = random_password.supabase_db_password.result
  }

  # set {
  #   name  = "logging.level"
  #   value = "INFO"
  # }
}

# resource "null_resource" "supabase_liveness_check" {
#   provisioner "local-exec" {
#     command = "timeout 300 bash -c 'while ! curl -sfI https://supabase.${var.server_base_domain}; do echo \"Waiting for supabase to be live.\" && sleep 1; done'"
#   }

#   depends_on = [helm_release.supabase]

#   lifecycle {
#     replace_triggered_by = [
#       helm_release.supabase
#     ]
#   }
# }
