variable "is_restore_mode" {
  type        = bool
  default     = false
  description = "Set to true if restoring in DR, otherwise false."
}

variable "velero_s3_access_key_id" {
  type        = string
  description = ""
}

variable "velero_s3_bucket_name" {
  type        = string
  description = ""
}

variable "velero_s3_region" {
  type        = string
  description = ""
}

variable "velero_s3_url" {
  type        = string
  description = ""
}

variable "velero_s3_secret_access_key" {
  type        = string
  sensitive   = true
  description = ""
}
