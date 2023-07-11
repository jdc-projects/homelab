data "keycloak_group" "app_group" {
  for_each = tomap({
    admins = "app_admins"
    users  = "app_users"
    guests = "app_guests"
  })

  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = each.value
}

resource "keycloak_role" "ocis_admin" {
  for_each = tomap({
    ocis_web = tomap({
      id = keycloak_openid_client.ocis_web.id
    })
    ocis_desktop = tomap({
      id = keycloak_openid_client.ocis_desktop.id
    })
    ocis_android = tomap({
      id = keycloak_openid_client.ocis_android.id
    })
    ocis_ios = tomap({
      id = keycloak_openid_client.ocis_ios.id
    })
  })

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value.id
  name        = "ocisAdmin"
  description = "OCIS Admin"
}

resource "keycloak_role" "ocis_user" {
  for_each = tomap({
    ocis_web = tomap({
      id = keycloak_openid_client.ocis_web.id
    })
    ocis_desktop = tomap({
      id = keycloak_openid_client.ocis_desktop.id
    })
    ocis_android = tomap({
      id = keycloak_openid_client.ocis_android.id
    })
    ocis_ios = tomap({
      id = keycloak_openid_client.ocis_ios.id
    })
  })

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value.id
  name        = "ocisUser"
  description = "OCIS User"
}

resource "keycloak_role" "ocis_guest" {
  for_each = tomap({
    ocis_web = tomap({
      id = keycloak_openid_client.ocis_web.id
    })
    ocis_desktop = tomap({
      id = keycloak_openid_client.ocis_desktop.id
    })
    ocis_android = tomap({
      id = keycloak_openid_client.ocis_android.id
    })
    ocis_ios = tomap({
      id = keycloak_openid_client.ocis_ios.id
    })
  })

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value.id
  name        = "ocisGuest"
  description = "OCIS Guest"
}

resource "keycloak_role" "ocis_composite" {
  for_each = tomap({
    ocis_admin = keycloak_role.ocis_admin
    ocis_user  = keycloak_role.ocis_user
    ocis_guest = keycloak_role.ocis_guest
  })

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name        = each.value["ocis_web"].name
  description = each.value["ocis_web"].description

  composite_roles = [
    each.value["ocis_web"].id,
    each.value["ocis_desktop"].id,
    each.value["ocis_android"].id,
    each.value["ocis_ios"].id,
  ]
}

resource "keycloak_group_roles" "ocis" {
  for_each = tomap({
    ocis_admin = tomap({
      role_id  = keycloak_role.ocis_composite["ocis_admin"].id
      group_id = data.keycloak_group.app_group["admins"]
    })
    ocis_user = tomap({
      role_id  = keycloak_role.ocis_composite["ocis_user"].id
      group_id = data.keycloak_group.app_group["users"]
    })
    ocis_guest = tomap({
      role_id  = keycloak_role.ocis_composite["ocis_guest"].id
      group_id = data.keycloak_group.app_group["guests"]
    })
  })

  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = each.value.group_id

  role_ids = [
    each.value.role_id
  ]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_claim_mapper" {
  for_each = tomap({
    ocis_web = tomap({
      id        = keycloak_openid_client.ocis_web.id
      client_id = keycloak_openid_client.ocis_web.client_id
    })
    ocis_desktop = tomap({
      id        = keycloak_openid_client.ocis_desktop.id
      client_id = keycloak_openid_client.ocis_desktop.client_id
    })
    ocis_android = tomap({
      id        = keycloak_openid_client.ocis_android.id
      client_id = keycloak_openid_client.ocis_android.client_id
    })
    ocis_ios = tomap({
      id        = keycloak_openid_client.ocis_ios.id
      client_id = keycloak_openid_client.ocis_ios.client_id
    })
  })

  realm_id                    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id                   = each.value.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = each.value.client_id

  multivalued = "true"

  add_to_id_token     = "false"
  add_to_access_token = "false"
  add_to_userinfo     = "true"
}
