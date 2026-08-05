output "service_host" {
  value       = "${var.name_prefix}:7233"
  description = "Temporal gRPC address (host:port) for workers."
}

output "db_cluster_name" {
  value       = kubernetes_manifest.temporal_db.manifest.metadata.name
  description = "CNPG cluster name for the Temporal database."
}
