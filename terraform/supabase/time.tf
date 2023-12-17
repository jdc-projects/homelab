locals {
  jwt_validity_years = 5

  jwt_iat = time_rotating.jwt_iat.unix
  jwt_exp = time_offset.jwt_exp.unix
}

resource "time_rotating" "jwt_iat" {
  rfc3339 = timestamp()

  rotation_years  = local.jwt_validity_years - 1
  rotation_months = 6
}

resource "time_offset" "jwt_exp" {
  base_rfc3339 = time_rotating.jwt_iat.rfc3339

  offset_years = local.jwt_validity_years

  lifecycle {
    replace_triggered_by = [time_rotating.jwt_iat]
  }
}
