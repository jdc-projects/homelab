variable "namespace" {
  description = "Namespace in which to create the GrafanaDashboard CRs."
  type        = string
}

variable "dashboards" {
  description = "Map of dashboard name -> Grafana dashboard JSON content. Each entry becomes a GrafanaDashboard CR named after its key."
  type        = map(string)
}
