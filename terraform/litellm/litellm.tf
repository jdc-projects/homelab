# resource "helm_release" "langfuse" {
#   name      = "langfuse"
#   namespace = kubernetes_namespace.ollama.metadata[0].name

#   repository = "https://langfuse.github.io/langfuse-k8s"
#   chart      = "langfuse"
#   version    = "0.12.1"

#   timeout = 600

#   # keycloak sso *****
#   set {
#     name  = "langfuse.nextauth.PLACEHOLDER"
#     value = ""
#   }
#   set {
#     name  = "langfuse.nextauth.PLACEHOLDER"
#     value = ""
#   }
#   set {
#     name  = "langfuse.nextauth.PLACEHOLDER"
#     value = ""
#   }
#   set {
#     name  = "langfuse.nextauth.PLACEHOLDER"
#     value = ""
#   }

#   set {
#     name  = "langfuse.salt"
#     value = "" # *****
#   }
#   set {
#     name  = "langfuse.telemetryEnabled"
#     value = "false"
#   }
#   set {
#     name  = "nextPublicSignUpDisabled"
#     value = "true"
#   }

#   # ***** additional env for authenticating to services https://github.com/langfuse/langfuse-k8s/blob/main/charts/langfuse/values.yaml#L59
#   # *****

#   set {
#     name  = "postgres.host"
#     value = "" # *****
#   }
#   set_sensitive {
#     name  = "postgres.auth.username"
#     value = "" # *****
#   }
#   set_sensitive {
#     name  = "postgres.auth.password"
#     value = "" # *****
#   }
#   set {
#     name  = "postgres.auth.database"
#     value = "" # *****
#   }
#   set {
#     name  = "postgres.deploy"
#     value = "false"
#   }

#   set {
#     name  = "clickhouse.deploy"
#     value = "false"
#   }
#   set_sensitive {
#     name  = "clickhouse.auth.password"
#     value = random_password.clickhouse_password.result
#   }
#   # ***** no value for the host...?

#   set {
#     name  = "valkey.deploy"
#     value = "false"
#   }
#   set {
#     name  = "valkey.auth.password"
#     value = random_password.langfuse_redis_password.result
#   }
#   # ***** no value for the host...?

#   set {
#     name  = "minio.deploy"
#     value = "false"
#   }
#   set {
#     name  = "minio.defaultBuckets"
#     value = "" # *****
#   }
#   set_sensitive {
#     name  = "minio.auth.rootUser"
#     value = random_password.minio_root_username.result
#   }
#   set_sensitive {
#     name  = "minio.auth.rootPassword"
#     value = random_password.minio_root_password.result
#   }
# }
