terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.18.0"
    }
  }
}

provider "google" {
  project = "dtc-de-course-486613"
  region  = "asia-south1"
}


resource "google_storage_bucket" "demo-bucket" {
  name          = "dtc-de-course-486613-terra-bucket"
  location      = "ASIA"
  force_destroy = true
  uniform_bucket_level_access = true
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}