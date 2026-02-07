variable "credentials" {
  description = "My credentials"
  default     = "./my-creds.json"
}

variable "project" {
  description = "Project"
  default     = "dtc-de-course-486613"
}

variable "region" {
  description = "Region name"
  default     = "us-central1"
}

variable "location" {
  description = "Project Location Name"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "demo_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "dtc-de-course-486613-terra-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}