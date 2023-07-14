data "archive_file" "keycloak_scripts_jar" {
  type             = "zip"
  output_path      = "./scripts.jar"
  source_dir       = "./scripts"
  output_file_mode = "0444"
}

resource "kubernetes_config_map" "keycloak_custom_scripts" {
  metadata {
    name      = "keycloak-custom-scripts"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  binary_data = {
    "scripts.jar" = filebase64(data.archive_file.keycloak_scripts_jar.output_path)
  }

  depends_on = [data.archive_file.keycloak_scripts_jar]
}
