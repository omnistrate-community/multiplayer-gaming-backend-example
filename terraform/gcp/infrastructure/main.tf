# GCP Infrastructure for Enterprise-Style Multiplayer Gaming Backend
# This module creates the foundational cloud infrastructure including:
# - Cloud Storage buckets for game assets and analytics
# - IAM service accounts for service authentication
# - Cloud Logging resources for monitoring

provider "google" {
  project = "{{ $sys.deploymentCell.gcpProjectId }}"
  region  = "{{ $sys.deploymentCell.region }}"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# Cloud Storage Bucket for Game Assets
resource "google_storage_bucket" "game_assets" {
  name     = "enterprise-gaming-assets-{{ $sys.id }}"
  location = "{{ $sys.deploymentCell.region }}"
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  encryption {
    default_kms_key_name = google_kms_crypto_key.gaming_key.id
  }
  
  labels = {
    environment = "{{ $var.environment }}"
    service     = "enterprise-gaming-backend"
    managed-by  = "omnistrate"
  }
}

# Cloud Storage Bucket for Analytics Data
resource "google_storage_bucket" "analytics_data" {
  name     = "enterprise-gaming-analytics-{{ $sys.id }}"
  location = "{{ $sys.deploymentCell.region }}"
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  encryption {
    default_kms_key_name = google_kms_crypto_key.gaming_key.id
  }
  
  labels = {
    environment = "{{ $var.environment }}"
    service     = "enterprise-gaming-backend"
    managed-by  = "omnistrate"
  }
}

# KMS Key Ring and Key for encryption
resource "google_kms_key_ring" "gaming_keyring" {
  name     = "enterprise-gaming-keyring-{{ $sys.id }}"
  location = "{{ $sys.deploymentCell.region }}"
}

resource "google_kms_crypto_key" "gaming_key" {
  name     = "enterprise-gaming-key-{{ $sys.id }}"
  key_ring = google_kms_key_ring.gaming_keyring.id
  
  rotation_period = "7776000s" # 90 days
  
  labels = {
    environment = "{{ $var.environment }}"
    service     = "enterprise-gaming-backend"
    managed-by  = "omnistrate"
  }
}

# Service Account for Player Service
resource "google_service_account" "player_service" {
  account_id   = "enterprise-gaming-player-svc-{{ $sys.id }}"
  display_name = "Enterprise Gaming Player Service"
  description  = "Service account for player service workload identity"
}

# Service Account for Analytics Service
resource "google_service_account" "analytics_service" {
  account_id   = "enterprise-gaming-analytics-svc-{{ $sys.id }}"
  display_name = "Enterprise Gaming Analytics Service"
  description  = "Service account for analytics service workload identity"
}

# Service Account for Kafka Service
resource "google_service_account" "kafka_service" {
  account_id   = "enterprise-gaming-kafka-svc-{{ $sys.id }}"
  display_name = "Enterprise Gaming Kafka Service"
  description  = "Service account for Kafka service workload identity"
}

# IAM bindings for Player Service
resource "google_storage_bucket_iam_member" "player_service_assets_access" {
  bucket = google_storage_bucket.game_assets.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.player_service.email}"
}

# IAM bindings for Analytics Service
resource "google_storage_bucket_iam_member" "analytics_service_access" {
  bucket = google_storage_bucket.analytics_data.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.analytics_service.email}"
}

# Workload Identity bindings
resource "google_service_account_iam_member" "player_service_workload_identity" {
  service_account_id = google_service_account.player_service.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:{{ $sys.deploymentCell.gcpProjectId }}.svc.id.goog[{{ $sys.deployment.namespace }}/player-service-sa]"
}

resource "google_service_account_iam_member" "analytics_service_workload_identity" {
  service_account_id = google_service_account.analytics_service.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:{{ $sys.deploymentCell.gcpProjectId }}.svc.id.goog[{{ $sys.deployment.namespace }}/analytics-service-sa]"
}

resource "google_service_account_iam_member" "kafka_service_workload_identity" {
  service_account_id = google_service_account.kafka_service.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:{{ $sys.deploymentCell.gcpProjectId }}.svc.id.goog[{{ $sys.deployment.namespace }}/kafka-sa]"
}

# Cloud Logging Log Sinks
resource "google_logging_project_sink" "player_service_logs" {
  name = "enterprise-gaming-player-service-{{ $sys.id }}"
  
  destination = "storage.googleapis.com/${google_storage_bucket.analytics_data.name}/logs/player-service"
  
  filter = "resource.type=\"k8s_container\" resource.labels.container_name=\"player-service\" resource.labels.namespace_name=\"{{ $sys.deployment.namespace }}\""
  
  unique_writer_identity = true
}

resource "google_logging_project_sink" "game_session_logs" {
  name = "enterprise-gaming-game-session-{{ $sys.id }}"
  
  destination = "storage.googleapis.com/${google_storage_bucket.analytics_data.name}/logs/game-session"
  
  filter = "resource.type=\"k8s_container\" resource.labels.container_name=\"game-session-service\" resource.labels.namespace_name=\"{{ $sys.deployment.namespace }}\""
  
  unique_writer_identity = true
}

# Global IP for load balancer
resource "google_compute_global_address" "gaming_ip" {
  name = "enterprise-gaming-global-ip-{{ $sys.id }}"
}

# Outputs
output "game_assets_bucket_name" {
  value = google_storage_bucket.game_assets.name
  description = "Name of the Cloud Storage bucket for game assets"
}

output "analytics_bucket_name" {
  value = google_storage_bucket.analytics_data.name
  description = "Name of the Cloud Storage bucket for analytics data"
}

output "player_service_account" {
  value = google_service_account.player_service.email
  description = "Email of the service account for player service"
}

output "analytics_service_account" {
  value = google_service_account.analytics_service.email
  description = "Email of the service account for analytics service"
}

output "kafka_service_account" {
  value = google_service_account.kafka_service.email
  description = "Email of the service account for Kafka service"
}

output "global_ip_name" {
  value = google_compute_global_address.gaming_ip.name
  description = "Name of the global IP address"
}

output "global_ip_address" {
  value = google_compute_global_address.gaming_ip.address
  description = "Global IP address for load balancer"
}

output "kms_key_id" {
  value = google_kms_crypto_key.gaming_key.id
  description = "ID of the KMS key for encryption"
}
