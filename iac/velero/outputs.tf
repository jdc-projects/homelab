output "velero_namespace_name" {
  value = kubernetes_namespace.velero.metadata[0].name
}

output "nightly_backup_name" {
  value = local.nightly_backup_name
}
