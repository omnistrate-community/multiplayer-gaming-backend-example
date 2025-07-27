# Output values for Azure data layer components

# SQL Server and Database Outputs
output "sql_server_name" {
  value       = azurerm_mssql_server.gaming.name
  description = "Name of the Azure SQL Server"
}

output "sql_server_fqdn" {
  value       = azurerm_mssql_server.gaming.fully_qualified_domain_name
  description = "Fully qualified domain name of the Azure SQL Server"
}

output "player_db_endpoint" {
  value       = azurerm_mssql_server.gaming.fully_qualified_domain_name
  description = "Endpoint for the players database"
}

output "player_db_name" {
  value       = azurerm_mssql_database.players.name
  description = "Name of the players database"
}

output "player_db_username" {
  value       = azurerm_mssql_server.gaming.administrator_login
  description = "Username for the players database"
}

output "player_db_password" {
  value       = random_password.sql_admin_password.result
  description = "Password for the players database"
  sensitive   = true
}

output "game_sessions_db_endpoint" {
  value       = azurerm_mssql_server.gaming.fully_qualified_domain_name
  description = "Endpoint for the game sessions database"
}

output "game_sessions_db_name" {
  value       = azurerm_mssql_database.game_sessions.name
  description = "Name of the game sessions database"
}

output "leaderboards_db_endpoint" {
  value       = azurerm_mssql_server.gaming.fully_qualified_domain_name
  description = "Endpoint for the leaderboards database"
}

output "leaderboards_db_name" {
  value       = azurerm_mssql_database.leaderboards.name
  description = "Name of the leaderboards database"
}

# Redis Cache Outputs
output "redis_endpoint" {
  value       = azurerm_redis_cache.gaming.hostname
  description = "Hostname of the Redis cache"
}

output "redis_port" {
  value       = azurerm_redis_cache.gaming.ssl_port
  description = "SSL port of the Redis cache"
}

output "redis_primary_key" {
  value       = azurerm_redis_cache.gaming.primary_access_key
  description = "Primary access key for Redis cache"
  sensitive   = true
}

output "redis_connection_string" {
  value       = "${azurerm_redis_cache.gaming.hostname}:${azurerm_redis_cache.gaming.ssl_port},password=${azurerm_redis_cache.gaming.primary_access_key},ssl=True,abortConnect=False"
  description = "Connection string for Redis cache"
  sensitive   = true
}

# Cosmos DB Outputs
output "cosmos_db_endpoint" {
  value       = azurerm_cosmosdb_account.gaming.endpoint
  description = "Endpoint of the Cosmos DB account"
}

output "cosmos_db_primary_key" {
  value       = azurerm_cosmosdb_account.gaming.primary_key
  description = "Primary key of the Cosmos DB account"
  sensitive   = true
}

output "cosmos_db_connection_strings" {
  value       = azurerm_cosmosdb_account.gaming.connection_strings
  description = "Connection strings for Cosmos DB"
  sensitive   = true
}

output "game_state_database_name" {
  value       = azurerm_cosmosdb_sql_database.game_state.name
  description = "Name of the game state database in Cosmos DB"
}

output "session_data_container_name" {
  value       = azurerm_cosmosdb_sql_container.session_data.name
  description = "Name of the session data container in Cosmos DB"
}

output "player_game_state_container_name" {
  value       = azurerm_cosmosdb_sql_container.player_game_state.name
  description = "Name of the player game state container in Cosmos DB"
}

# Synapse Analytics Outputs
output "synapse_workspace_name" {
  value       = azurerm_synapse_workspace.gaming.name
  description = "Name of the Synapse workspace"
}

output "synapse_workspace_connectivity_endpoints" {
  value       = azurerm_synapse_workspace.gaming.connectivity_endpoints
  description = "Connectivity endpoints for the Synapse workspace"
}

output "analytics_database_name" {
  value       = azurerm_synapse_sql_pool.analytics.name
  description = "Name of the analytics database (SQL pool)"
}

output "analytics_sql_pool" {
  value       = azurerm_synapse_sql_pool.analytics.name
  description = "Name of the analytics SQL pool"
}

output "synapse_sql_endpoint" {
  value       = azurerm_synapse_workspace.gaming.sql_endpoint
  description = "SQL endpoint for the Synapse workspace"
}

# Key Vault Secret References
output "sql_admin_password_secret_id" {
  value       = azurerm_key_vault_secret.sql_admin_password.id
  description = "Key Vault secret ID for SQL admin password"
}

output "redis_password_secret_id" {
  value       = azurerm_key_vault_secret.redis_password.id
  description = "Key Vault secret ID for Redis password"
}

# Connection Information Summary
output "database_connections" {
  value = {
    players_db = {
      endpoint = azurerm_mssql_server.gaming.fully_qualified_domain_name
      database = azurerm_mssql_database.players.name
      username = azurerm_mssql_server.gaming.administrator_login
    }
    game_sessions_db = {
      endpoint = azurerm_mssql_server.gaming.fully_qualified_domain_name
      database = azurerm_mssql_database.game_sessions.name
      username = azurerm_mssql_server.gaming.administrator_login
    }
    leaderboards_db = {
      endpoint = azurerm_mssql_server.gaming.fully_qualified_domain_name
      database = azurerm_mssql_database.leaderboards.name
      username = azurerm_mssql_server.gaming.administrator_login
    }
    redis = {
      endpoint = azurerm_redis_cache.gaming.hostname
      port     = azurerm_redis_cache.gaming.ssl_port
    }
    cosmos_db = {
      endpoint      = azurerm_cosmosdb_account.gaming.endpoint
      database_name = azurerm_cosmosdb_sql_database.game_state.name
    }
    synapse = {
      sql_endpoint = azurerm_synapse_workspace.gaming.sql_endpoint
      sql_pool     = azurerm_synapse_sql_pool.analytics.name
    }
  }
  description = "Summary of all database connection information"
}
