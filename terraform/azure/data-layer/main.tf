# Azure Data Layer for Enterprise-Style Multiplayer Gaming Backend
# This module creates the data storage infrastructure including:
# - Azure SQL Database for different game services
# - Azure Cache for Redis for caching and session management  
# - Cosmos DB for real-time data and NoSQL workloads
# - Azure Synapse Analytics for analytics workloads

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source for existing resource group (created by infrastructure layer)
data "azurerm_resource_group" "gaming" {
  name = "rg-enterprise-gaming-{{ $sys.id }}"
}

# Data source for existing Key Vault
data "azurerm_key_vault" "gaming" {
  name                = "kv-gaming-{{ $sys.id | lower | replace("-", "") }}"
  resource_group_name = data.azurerm_resource_group.gaming.name
}

# Random password for SQL Server admin
resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

# Store SQL admin password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = data.azurerm_key_vault.gaming.id
}

# Azure SQL Server
resource "azurerm_mssql_server" "gaming" {
  name                         = "sql-gaming-{{ $sys.id | lower | replace("-", "") }}"
  resource_group_name          = data.azurerm_resource_group.gaming.name
  location                     = data.azurerm_resource_group.gaming.location
  version                      = "12.0"
  administrator_login          = "gaming_admin"
  administrator_login_password = random_password.sql_admin_password.result

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  tags = {
    Name        = "Gaming-SQL-Server-{{ $sys.id }}"
    Environment = var.environment
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Azure SQL Database for Players
resource "azurerm_mssql_database" "players" {
  name           = "players"
  server_id      = azurerm_mssql_server.gaming.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 100
  sku_name       = "S2"
  zone_redundant = false

  threat_detection_policy {
    state                = "Enabled"
    email_addresses      = ["admin@enterprise-gaming.com"]
    retention_days       = 30
    use_server_default   = false
  }

  tags = {
    Name        = "Players-Database-{{ $sys.id }}"
    Environment = var.environment
    Service     = "PlayerService"
    ManagedBy   = "Omnistrate"
  }
}

# Azure SQL Database for Game Sessions
resource "azurerm_mssql_database" "game_sessions" {
  name           = "game_sessions"
  server_id      = azurerm_mssql_server.gaming.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 250
  sku_name       = "S3"
  zone_redundant = false

  threat_detection_policy {
    state                = "Enabled"
    email_addresses      = ["admin@enterprise-gaming.com"]
    retention_days       = 30
    use_server_default   = false
  }

  tags = {
    Name        = "GameSessions-Database-{{ $sys.id }}"
    Environment = var.environment
    Service     = "GameSessionService"
    ManagedBy   = "Omnistrate"
  }
}

# Azure SQL Database for Leaderboards
resource "azurerm_mssql_database" "leaderboards" {
  name           = "leaderboards"
  server_id      = azurerm_mssql_server.gaming.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 50
  sku_name       = "S1"
  zone_redundant = false

  threat_detection_policy {
    state                = "Enabled"
    email_addresses      = ["admin@enterprise-gaming.com"]
    retention_days       = 30
    use_server_default   = false
  }

  tags = {
    Name        = "Leaderboards-Database-{{ $sys.id }}"
    Environment = var.environment
    Service     = "LeaderboardService"
    ManagedBy   = "Omnistrate"
  }
}

# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.gaming.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Random password for Redis
resource "random_password" "redis_password" {
  length  = 32
  special = true
}

# Store Redis password in Key Vault
resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = random_password.redis_password.result
  key_vault_id = data.azurerm_key_vault.gaming.id
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "gaming" {
  name                = "redis-gaming-{{ $sys.id | lower | replace("-", "") }}"
  location            = data.azurerm_resource_group.gaming.location
  resource_group_name = data.azurerm_resource_group.gaming.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  redis_version       = "6"

  redis_configuration {
    enable_authentication = true
  }

  tags = {
    Name        = "Gaming-Redis-{{ $sys.id }}"
    Environment = var.environment
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Cosmos DB Account for real-time game state
resource "azurerm_cosmosdb_account" "gaming" {
  name                = "cosmos-gaming-{{ $sys.id | lower | replace("-", "") }}"
  location            = data.azurerm_resource_group.gaming.location
  resource_group_name = data.azurerm_resource_group.gaming.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true
  enable_multiple_write_locations = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 86400
    max_staleness_prefix    = 1000000
  }

  geo_location {
    location          = data.azurerm_resource_group.gaming.location
    failover_priority = 0
    zone_redundant    = false
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = {
    Name        = "Gaming-CosmosDB-{{ $sys.id }}"
    Environment = var.environment
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Cosmos DB SQL Database for game state
resource "azurerm_cosmosdb_sql_database" "game_state" {
  name                = "game_state"
  resource_group_name = data.azurerm_resource_group.gaming.name
  account_name        = azurerm_cosmosdb_account.gaming.name
}

# Cosmos DB Container for real-time session data
resource "azurerm_cosmosdb_sql_container" "session_data" {
  name                  = "session_data"
  resource_group_name   = data.azurerm_resource_group.gaming.name
  account_name          = azurerm_cosmosdb_account.gaming.name
  database_name         = azurerm_cosmosdb_sql_database.game_state.name
  partition_key_path    = "/sessionId"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }

  unique_key {
    paths = ["/sessionId", "/playerId"]
  }
}

# Cosmos DB Container for player game state
resource "azurerm_cosmosdb_sql_container" "player_game_state" {
  name                  = "player_game_state"
  resource_group_name   = data.azurerm_resource_group.gaming.name
  account_name          = azurerm_cosmosdb_account.gaming.name
  database_name         = azurerm_cosmosdb_sql_database.game_state.name
  partition_key_path    = "/playerId"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Azure Synapse Analytics Workspace for analytics
resource "azurerm_synapse_workspace" "gaming" {
  name                                 = "synapse-gaming-{{ $sys.id | lower | replace("-", "") }}"
  resource_group_name                  = data.azurerm_resource_group.gaming.name
  location                            = data.azurerm_resource_group.gaming.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.analytics.id
  sql_administrator_login              = "gaming_admin"
  sql_administrator_login_password     = random_password.sql_admin_password.result

  aad_admin {
    login     = "AzureAD Admin"
    object_id = data.azurerm_client_config.current.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name        = "Gaming-Synapse-{{ $sys.id }}"
    Environment = var.environment
    Service     = "AnalyticsService"
    ManagedBy   = "Omnistrate"
  }
}

# Data source for analytics storage account
data "azurerm_storage_account" "analytics" {
  name                = "stanalyticsdata{{ $sys.id | lower | replace("-", "") }}"
  resource_group_name = data.azurerm_resource_group.gaming.name
}

# Data Lake Gen2 Filesystem for Synapse
resource "azurerm_storage_data_lake_gen2_filesystem" "analytics" {
  name               = "analytics"
  storage_account_id = data.azurerm_storage_account.analytics.id
}

# Synapse SQL Pool for analytics workloads
resource "azurerm_synapse_sql_pool" "analytics" {
  name                 = "analytics_pool"
  synapse_workspace_id = azurerm_synapse_workspace.gaming.id
  sku_name             = "DW100c"
  create_mode          = "Default"

  tags = {
    Name        = "Analytics-SQL-Pool-{{ $sys.id }}"
    Environment = var.environment
    Service     = "AnalyticsService"
    ManagedBy   = "Omnistrate"
  }
}

# Private Endpoint for SQL Server (optional, for enhanced security)
resource "azurerm_private_endpoint" "sql_server" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-sql-gaming-{{ $sys.id }}"
  location            = data.azurerm_resource_group.gaming.location
  resource_group_name = data.azurerm_resource_group.gaming.name
  subnet_id           = data.azurerm_subnet.private.id

  private_service_connection {
    name                           = "psc-sql-gaming-{{ $sys.id }}"
    private_connection_resource_id = azurerm_mssql_server.gaming.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = {
    Name        = "SQL-PrivateEndpoint-{{ $sys.id }}"
    Environment = var.environment
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Data source for private subnet (if private endpoints are enabled)
data "azurerm_subnet" "private" {
  count                = var.enable_private_endpoints ? 1 : 0
  name                 = "snet-aks-{{ $sys.id }}"
  virtual_network_name = "vnet-gaming-{{ $sys.id }}"
  resource_group_name  = data.azurerm_resource_group.gaming.name
}
