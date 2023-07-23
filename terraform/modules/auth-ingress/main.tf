data "terraform_remote_state" "oauth2_proxy" {
  backend = "kubernetes"

  config = {
    secret_suffix = "oauth2-proxy"
    config_path   = "../../cluster.yml"
    namespace     = "terraform-state"
  }
}
