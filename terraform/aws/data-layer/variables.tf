variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
}

variable "db_password" {
  description = "Password for RDS databases"
  type        = string
  sensitive   = true
}

variable "analytics_db_password" {
  description = "Password for analytics Redshift cluster"
  type        = string
  sensitive   = true
  default     = "AnalyticsPass123!"
}

variable "enable_analytics" {
  description = "Enable detailed game analytics collection"
  type        = bool
  default     = true
}
