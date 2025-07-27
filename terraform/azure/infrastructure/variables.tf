variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
}

variable "game_region" {
  description = "Primary game region for latency optimization"
  type        = string
  default     = "East US"
}

variable "enable_analytics" {
  description = "Enable detailed game analytics collection"
  type        = bool
  default     = true
}

variable "max_players_per_session" {
  description = "Maximum number of players per game session"
  type        = number
  default     = 64
}

variable "resource_group_location" {
  description = "Azure region for resource group"
  type        = string
  default     = "East US"
}

variable "enable_advanced_threat_protection" {
  description = "Enable advanced threat protection for storage accounts"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics workspace"
  type        = number
  default     = 90
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "GRS"
}
