# GCP Data Layer for Enterprise-Style Multiplayer Gaming Backend
# This module creates the data storage infrastructure including:
# - Cloud SQL instances for different game services
# - Memorystore Redis cluster for caching and session management
# - Firestore databases for real-time data

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

# Cloud SQL Instance for Player Data
resource "google_sql_database_instance" "player_database" {
  name             = "enterprise-gaming-player-db-{{ $sys.id }}"
  database_version = "MYSQL_8_0"
  region           = "{{ $sys.deploymentCell.region }}"
  
  deletion_protection = false
  
  settings {
    tier = "db-n1-standard-2"
    
    disk_type = "PD_SSD"
    disk_size = 100
    disk_autoresize = true
    disk_autoresize_limit = 1000
    
    backup_configuration {
      enabled    = true
      start_time = "07:00"
      binary_log_enabled = true
    }
    
    maintenance_window {
      day  = 7
      hour = 9
    }
    
    ip_configuration {
      ipv4_enabled = false
      private_network = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
      require_ssl = true
    }
    
    database_flags {
      name  = "innodb_buffer_pool_size"
      value = "75%"
    }
    
    user_labels = {
      environment = "{{ $var.environment }}"
      service     = "player-database"
      managed-by  = "omnistrate"
    }
  }
}

# Cloud SQL Database for Player Data
resource "google_sql_database" "player_db" {
  name     = "players"
  instance = google_sql_database_instance.player_database.name
}

# Cloud SQL User for Player Database
resource "google_sql_user" "player_db_user" {
  name     = "gaming_admin"
  instance = google_sql_database_instance.player_database.name
  password = var.db_password
}

# Cloud SQL Instance for Game Session Data
resource "google_sql_database_instance" "game_session_database" {
  name             = "enterprise-gaming-session-db-{{ $sys.id }}"
  database_version = "MYSQL_8_0"
  region           = "{{ $sys.deploymentCell.region }}"
  
  deletion_protection = false
  
  settings {
    tier = "db-n1-standard-4"
    
    disk_type = "PD_SSD"
    disk_size = 200
    disk_autoresize = true
    disk_autoresize_limit = 2000
    
    backup_configuration {
      enabled    = true
      start_time = "07:00"
      binary_log_enabled = true
    }
    
    maintenance_window {
      day  = 7
      hour = 9
    }
    
    ip_configuration {
      ipv4_enabled = false
      private_network = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
      require_ssl = true
    }
    
    database_flags {
      name  = "innodb_buffer_pool_size"
      value = "75%"
    }
    
    user_labels = {
      environment = "{{ $var.environment }}"
      service     = "game-session-database"
      managed-by  = "omnistrate"
    }
  }
}

# Cloud SQL Database for Game Session Data
resource "google_sql_database" "game_session_db" {
  name     = "game_sessions"
  instance = google_sql_database_instance.game_session_database.name
}

# Cloud SQL Instance for Leaderboard Data
resource "google_sql_database_instance" "leaderboard_database" {
  name             = "enterprise-gaming-leaderboard-db-{{ $sys.id }}"
  database_version = "MYSQL_8_0"
  region           = "{{ $sys.deploymentCell.region }}"
  
  deletion_protection = false
  
  settings {
    tier = "db-n1-standard-1"
    
    disk_type = "PD_SSD"
    disk_size = 50
    disk_autoresize = true
    disk_autoresize_limit = 500
    
    backup_configuration {
      enabled    = true
      start_time = "07:00"
      binary_log_enabled = true
    }
    
    maintenance_window {
      day  = 7
      hour = 9
    }
    
    ip_configuration {
      ipv4_enabled = false
      private_network = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
      require_ssl = true
    }
    
    user_labels = {
      environment = "{{ $var.environment }}"
      service     = "leaderboard-database"
      managed-by  = "omnistrate"
    }
  }
}

# Cloud SQL Database for Leaderboard Data
resource "google_sql_database" "leaderboard_db" {
  name     = "leaderboards"
  instance = google_sql_database_instance.leaderboard_database.name
}

# Memorystore Redis Instance
resource "google_redis_instance" "gaming_redis" {
  name           = "enterprise-gaming-redis-{{ $sys.id }}"
  tier           = "STANDARD_HA"
  memory_size_gb = 4
  region         = "{{ $sys.deploymentCell.region }}"
  
  redis_version = "REDIS_7_0"
  
  authorized_network = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
  
  auth_enabled = true
  
  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 9
        minutes = 0
      }
    }
  }
  
  labels = {
    environment = "{{ $var.environment }}"
    service     = "redis-cache"
    managed-by  = "omnistrate"
  }
}

# Firestore Database for Real-time Game State
resource "google_firestore_database" "game_state" {
  project     = "{{ $sys.deploymentCell.gcpProjectId }}"
  name        = "enterprise-gaming-state-{{ $sys.id }}"
  location_id = "{{ $sys.deploymentCell.region }}"
  type        = "FIRESTORE_NATIVE"
  
  app_engine_integration_mode = "DISABLED"
  concurrency_mode           = "OPTIMISTIC"
  
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
  delete_protection_state           = "DELETE_PROTECTION_DISABLED"
}

# BigQuery Dataset for Analytics (when analytics is enabled)
resource "google_bigquery_dataset" "analytics_dataset" {
  count = var.enable_analytics ? 1 : 0
  
  dataset_id  = "ea_gaming_analytics_{{ $sys.id }}"
  description = "Dataset for Enterprise Gaming Backend analytics"
  location    = "{{ $sys.deploymentCell.region }}"
  
  default_table_expiration_ms = 2592000000 # 30 days
  
  labels = {
    environment = "{{ $var.environment }}"
    service     = "analytics"
    managed-by  = "omnistrate"
  }
}

# BigQuery Table for Player Events
resource "google_bigquery_table" "player_events" {
  count = var.enable_analytics ? 1 : 0
  
  dataset_id = google_bigquery_dataset.analytics_dataset[0].dataset_id
  table_id   = "player_events"
  
  deletion_protection = false
  
  time_partitioning {
    type  = "DAY"
    field = "event_timestamp"
  }
  
  clustering = ["player_id", "event_type"]
  
  schema = jsonencode([
    {
      name = "player_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "event_type"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "event_timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "session_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "event_data"
      type = "JSON"
      mode = "NULLABLE"
    }
  ])
  
  labels = {
    environment = "{{ $var.environment }}"
    service     = "analytics"
    managed-by  = "omnistrate"
  }
}

# Outputs
output "player_db_endpoint" {
  value = google_sql_database_instance.player_database.private_ip_address
  description = "Cloud SQL private IP for player database"
}

output "player_db_username" {
  value = google_sql_user.player_db_user.name
  description = "Username for player database"
}

output "player_db_password" {
  value = google_sql_user.player_db_user.password
  description = "Password for player database"
  sensitive = true
}

output "game_session_db_endpoint" {
  value = google_sql_database_instance.game_session_database.private_ip_address
  description = "Cloud SQL private IP for game session database"
}

output "leaderboard_db_endpoint" {
  value = google_sql_database_instance.leaderboard_database.private_ip_address
  description = "Cloud SQL private IP for leaderboard database"
}

output "redis_endpoint" {
  value = google_redis_instance.gaming_redis.host
  description = "Memorystore Redis host"
}

output "redis_port" {
  value = google_redis_instance.gaming_redis.port
  description = "Memorystore Redis port"
}

output "firestore_database_name" {
  value = google_firestore_database.game_state.name
  description = "Firestore database name for game state"
}

output "analytics_dataset_id" {
  value = var.enable_analytics ? google_bigquery_dataset.analytics_dataset[0].dataset_id : null
  description = "BigQuery dataset ID for analytics"
}

output "analytics_warehouse_endpoint" {
  value = var.enable_analytics ? "bigquery.googleapis.com" : null
  description = "BigQuery analytics warehouse endpoint"
}
