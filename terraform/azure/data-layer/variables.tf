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

variable "enable_private_endpoints" {
  description = "Enable private endpoints for enhanced security"
  type        = bool
  default     = false
}

variable "sql_server_sku" {
  description = "SKU for Azure SQL databases"
  type        = string
  default     = "S2"
}

variable "redis_capacity" {
  description = "Capacity for Azure Cache for Redis"
  type        = number
  default     = 2
}

variable "redis_family" {
  description = "Family for Azure Cache for Redis"
  type        = string
  default     = "C"
}

variable "redis_sku_name" {
  description = "SKU name for Azure Cache for Redis"
  type        = string
  default     = "Standard"
}

variable "cosmos_consistency_level" {
  description = "Consistency level for Cosmos DB"
  type        = string
  default     = "BoundedStaleness"
}

variable "synapse_sql_pool_sku" {
  description = "SKU for Synapse SQL Pool"
  type        = string
  default     = "DW100c"
}

variable "enable_cosmos_serverless" {
  description = "Enable serverless mode for Cosmos DB"
  type        = bool
  default     = true
}

variable "sql_threat_detection_emails" {
  description = "Email addresses for SQL threat detection notifications"
  type        = list(string)
  default     = ["admin@enterprise-gaming.com"]
}

variable "backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 30
}
