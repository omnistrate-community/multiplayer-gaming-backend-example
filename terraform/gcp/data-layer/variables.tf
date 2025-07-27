variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
}

variable "db_password" {
  description = "Password for Cloud SQL databases"
  type        = string
  sensitive   = true
}

variable "enable_analytics" {
  description = "Enable detailed game analytics collection"
  type        = bool
  default     = true
}
