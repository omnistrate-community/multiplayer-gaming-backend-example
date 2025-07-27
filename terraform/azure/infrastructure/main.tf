# Azure Infrastructure for Enterprise-Style Multiplayer Gaming Backend
# This module creates the foundational cloud infrastructure including:
# - Storage accounts for game assets and analytics
# - Managed identities for service authentication
# - Log Analytics workspace for monitoring
# - Key Vault for secrets management

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Resource Group for all gaming infrastructure
resource "azurerm_resource_group" "gaming" {
  name     = "rg-enterprise-gaming-{{ $sys.id }}"
  location = "{{ $sys.deploymentCell.region }}"

  tags = {
    Name        = "Enterprise-Gaming-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Storage Account for Game Assets
resource "azurerm_storage_account" "game_assets" {
  name                     = "stgameassets{{ $sys.id | lower | replace("-", "") }}"
  resource_group_name      = azurerm_resource_group.gaming.name
  location                = azurerm_resource_group.gaming.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Name        = "GameAssets-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Container for game assets
resource "azurerm_storage_container" "game_assets" {
  name                  = "game-assets"
  storage_account_name  = azurerm_storage_account.game_assets.name
  container_access_type = "private"
}

# Storage Account for Analytics Data
resource "azurerm_storage_account" "analytics_data" {
  name                     = "stanalyticsdata{{ $sys.id | lower | replace("-", "") }}"
  resource_group_name      = azurerm_resource_group.gaming.name
  location                = azurerm_resource_group.gaming.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled          = true  # Enable hierarchical namespace for Data Lake

  blob_properties {
    delete_retention_policy {
      days = 365
    }
  }

  tags = {
    Name        = "AnalyticsData-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Container for analytics data
resource "azurerm_storage_container" "analytics_data" {
  name                  = "analytics-data"
  storage_account_name  = azurerm_storage_account.analytics_data.name
  container_access_type = "private"
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "gaming" {
  name                = "log-enterprise-gaming-{{ $sys.id }}"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = {
    Name        = "Gaming-Logs-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Key Vault for secrets
resource "azurerm_key_vault" "gaming" {
  name                = "kv-gaming-{{ $sys.id | lower | replace("-", "") }}"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
    ]
  }

  tags = {
    Name        = "Gaming-Secrets-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# User Assigned Managed Identity for Player Service
resource "azurerm_user_assigned_identity" "player_service" {
  name                = "id-player-service-{{ $sys.id }}"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location

  tags = {
    Name        = "PlayerService-Identity-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# User Assigned Managed Identity for Game Session Service
resource "azurerm_user_assigned_identity" "game_session_service" {
  name                = "id-game-session-{{ $sys.id }}"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location

  tags = {
    Name        = "GameSession-Identity-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# User Assigned Managed Identity for Analytics Service
resource "azurerm_user_assigned_identity" "analytics_service" {
  name                = "id-analytics-{{ $sys.id }}"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location

  tags = {
    Name        = "Analytics-Identity-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Role assignment for analytics service to access storage
resource "azurerm_role_assignment" "analytics_storage_contributor" {
  scope                = azurerm_storage_account.analytics_data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.analytics_service.principal_id
}

# Role assignment for player service to access Key Vault
resource "azurerm_role_assignment" "player_service_key_vault" {
  scope                = azurerm_key_vault.gaming.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.player_service.principal_id
}

# Application Gateway for ingress (if needed)
resource "azurerm_public_ip" "app_gateway" {
  name                = "pip-appgw-gaming-{{ $sys.id }}"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name        = "AppGateway-IP-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Virtual Network for gaming infrastructure
resource "azurerm_virtual_network" "gaming" {
  name                = "vnet-gaming-{{ $sys.id }}"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    Name        = "Gaming-VNet-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-{{ $sys.id }}"
  resource_group_name  = azurerm_resource_group.gaming.name
  virtual_network_name = azurerm_virtual_network.gaming.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for Application Gateway
resource "azurerm_subnet" "app_gateway" {
  name                 = "snet-appgw-{{ $sys.id }}"
  resource_group_name  = azurerm_resource_group.gaming.name
  virtual_network_name = azurerm_virtual_network.gaming.name
  address_prefixes     = ["10.0.2.0/24"]
}
