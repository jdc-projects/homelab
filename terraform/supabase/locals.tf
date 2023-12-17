# source: https://github.com/supabase/supabase/blob/v0.23.10/docker/.env.example
locals {
  ############
  # Secrets
  # YOU MUST CHANGE THESE BEFORE GOING INTO PRODUCTION
  ############

  # POSTGRES_PASSWORD = ""
  # JWT_SECRET = ""
  # ANON_KEY = ""
  # SERVICE_ROLE_KEY = ""
  # DASHBOARD_USERNAME = ""
  # DASHBOARD_PASSWORD = ""

  ############
  # Database - You can change these to any PostgreSQL database that has logical replication enabled.
  ############

  # POSTGRES_HOST = ""
  # POSTGRES_DB = ""
  # POSTGRES_PORT = ""

  ############
  # API Proxy - Configuration for the Kong Reverse proxy.
  ############

  # these are not relevant, since they are host ports in the Docker Compose
  # KONG_HTTP_PORT = ""
  # KONG_HTTPS_PORT = ""

  ############
  # API - Configuration for PostgREST.
  ############

  # PGRST_DB_SCHEMAS = ""

  ############
  # Auth - Configuration for the GoTrue authentication server.
  ############

  SITE_URL                 = "https://supabase.${var.server_base_domain}"
  ADDITIONAL_REDIRECT_URLS = ""
  JWT_EXPIRY               = "3600"
  DISABLE_SIGNUP           = "false"
  API_EXTERNAL_URL         = "https://supabase.${var.server_base_domain}"

  MAILER_URLPATHS_CONFIRMATION = "/auth/v1/verify"
  MAILER_URLPATHS_INVITE       = "/auth/v1/verify"
  MAILER_URLPATHS_RECOVERY     = "/auth/v1/verify"
  MAILER_URLPATHS_EMAIL_CHANGE = "/auth/v1/verify"

  ENABLE_EMAIL_SIGNUP      = "true"
  ENABLE_EMAIL_AUTOCONFIRM = "false"
  SMTP_ADMIN_EMAIL         = "noreply@${var.server_base_domain}"
  # SMTP_HOST = ""
  # SMTP_PORT = ""
  # SMTP_USER = ""
  # SMTP_PASS = ""
  SMTP_SENDER_NAME = "Supabase"

  ENABLE_PHONE_SIGNUP      = "false"
  ENABLE_PHONE_AUTOCONFIRM = "false"

  ############
  # Studio - Configuration for the Dashboard
  ############

  STUDIO_DEFAULT_ORGANIZATION = "Default organisation"
  STUDIO_DEFAULT_PROJECT      = "Default project"

  # STUDIO_PORT = ""
  SUPABASE_PUBLIC_URL = "https://supabase.${var.server_base_domain}"

  # IMGPROXY_ENABLE_WEBP_DETECTION = ""

  ############
  # Functions - Configuration for Functions
  ############

  # FUNCTIONS_VERIFY_JWT = ""

  ############
  # Logs - Configuration for Logflare
  # Please refer to https://supabase.com/docs/reference/self-hosting-analytics/introduction
  ############

  # LOGFLARE_LOGGER_BACKEND_API_KEY = ""

  # LOGFLARE_API_KEY = ""

  # DOCKER_SOCKET_LOCATION = ""

  # GOOGLE_PROJECT_ID     = ""
  # GOOGLE_PROJECT_NUMBER = ""
}
