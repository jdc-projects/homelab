terraform {
  backend "kubernetes" {
    secret_suffix = "clickhouse-operator"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}
