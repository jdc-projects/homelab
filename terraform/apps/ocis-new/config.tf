resource "kubernetes_secret" "ocis_global_config" {
  metadata {
    name      = "ocis-global-config"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    OCIS_LOG_LEVEL = "info"
    OCIS_LOG_PRETTY = "false"
    OCIS_LOG_COLOR = "false"
    OCIS_URL = "https://files.${var.server_base_domain}"
    OCIS_OIDC_ISSUER = ""
    WEB_OIDC_METADATA_URL = ""
    OCIS_OIDC_CLIENT_ID = ""
    WEB_OIDC_POST_LOGOUT_REDIRECT_URI = "https://files.${var.server_base_domain}"
    OCIS_LDAP_SERVER_WRITE_ENABLED = "false"
    OCIS_LDAP_URI = ""
    OCIS_LDAP_BIND_DN = ""
    OCIS_LDAP_BIND_PASSWORD = ""
    OCIS_LDAP_USER_BASE_DN = "ou=people,dc=idm,dc=${var.server_base_domain}"
    OCIS_LDAP_USER_SCHEMA_ID = "uid"
    OCIS_LDAP_USER_OBJECTCLASS = "person"
    OCIS_LDAP_GROUP_SCHEMA_ID = "uid"
    OCIS_LDAP_GROUP_BASE_DN = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    PROXY_AUTOPROVISION_ACCOUNTS = "true"
    PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc"
    PROXY_TLS = "false"
    PROXY_USER_OIDC_CLAIM = "preferred_username"
    PROXY_USER_CS3_CLAIM = "userid"
  }
}

resource "kubernetes_secret" "ocis_config_files" {
  metadata {
    name      = "ocis-config-files"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    "idp.yaml" = <<-EOF
      clients:
      - id: web
        name: ownCloud Web app
        trusted: true
        secret: ""
        redirect_uris:
        - '{{OCIS_URL}}/'
        - '{{OCIS_URL}}/oidc-callback.html'
        - '{{OCIS_URL}}/oidc-silent-redirect.html'
        origins:
        - '{{OCIS_URL}}'
        application_type: ""
      - id: xdXOt13JKxym1B1QcEncf2XDkLAexMBFwiT9j6EfhhHFJhs2KM9jbjTmf8JBXE69
        name: ownCloud desktop app
        trusted: false
        secret: UBntmLjC2yYCeHwsyj73Uwo9TAaecAetRwMw0xYcvNL9yRdLSUi0hUAHfvCHFeFh
        redirect_uris:
        - http://127.0.0.1
        - http://localhost
        origins: []
        application_type: native
      - id: e4rAsNUSIUs0lF4nbv9FmCeUkTlV9GdgTLDH1b5uie7syb90SzEVrbN7HIpmWJeD
        name: ownCloud Android app
        trusted: false
        secret: dInFYGV33xKzhbRmpqQltYNdfLdJIfJ9L5ISoKhNoT9qZftpdWSP71VrpGR9pmoD
        redirect_uris:
        - oc://android.owncloud.com
        origins: []
        application_type: native
      - id: mxd5OQDk6es5LzOzRvidJNfXLUZS2oN3oUFeXPP8LpPrhx3UroJFduGEYIBOxkY1
        name: ownCloud iOS app
        trusted: false
        secret: KFeFWWEZO9TkisIQzR3fo7hfiMXlOpaqP8CFuTbSHzV1TUuGECglPxpiVKJfOXIx
        redirect_uris:
        - oc://ios.owncloud.com
        origins: []
        application_type: native
    EOF
  }
}
