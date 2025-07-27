variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
}

variable "game_region" {
  description = "Primary game region for latency optimization"
  type        = string
  default     = "us-central1"
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
