# resource "random_password" "supabase_admin_username" {
#   length  = 16
#   numeric = false
#   special = false
#   upper   = false
# }

# resource "random_password" "supabase_admin_password" {
#   length  = 16
#   numeric = true
#   special = false
#   upper   = true
# }

resource "random_password" "supabase_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "supabase_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    username = random_password.supabase_db_username.result
    password = random_password.supabase_db_password.result
  }
}

resource "random_password" "jwt_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}
