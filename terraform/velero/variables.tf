variable "velero_s3_access_key_id" {
  type = string
  description = ""
}

variable "velero_s3_bucket_name" {
  type = string
  description = ""
}

variable "velero_s3_url" {
  type = string
  description = ""
}

variable "velero_s3_secret_access_key" {
  type = string
  sensitive = true
  description = ""
}
