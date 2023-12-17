resource "kubernetes_secret" "jwt" {
  metadata {
    name      = "jwt"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    secret      = random_password.jwt_secret.result
    anon-key    = jwt_hashed_token.anon_key.token
    service-key = jwt_hashed_token.service_key.token
  }
}

resource "kubernetes_secret" "realtime" {
  metadata {
    name      = "realtime"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    key-base = ""
  }
}
