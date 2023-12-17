resource "jwt_hashed_token" "anon_key" {
  claims_json = <<-EOF
    {
      "role": "anon",
      "iss": "supabase",
      "iat": ${local.jwt_iat},
      "exp": ${local.jwt_exp}
    }
  EOF

  secret = random_password.jwt_secret.result

  algorithm = "HS256"
}

resource "jwt_hashed_token" "service_key" {
  claims_json = <<-EOF
    {
      "role": "service_role",
      "iss": "supabase",
      "iat": ${local.jwt_iat},
      "exp": ${local.jwt_exp}
    }
  EOF

  secret = random_password.jwt_secret.result

  algorithm = "HS256"
}
