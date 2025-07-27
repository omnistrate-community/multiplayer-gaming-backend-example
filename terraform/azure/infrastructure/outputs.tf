# Output values for Azure infrastructure components

output "resource_group_name" {
  value       = azurerm_resource_group.gaming.name
  description = "Name of the resource group containing all gaming infrastructure"
}

output "resource_group_location" {
  value       = azurerm_resource_group.gaming.location
  description = "Location of the resource group"
}

# Storage Account Outputs
output "game_assets_storage_account_name" {
  value       = azurerm_storage_account.game_assets.name
  description = "Name of the storage account for game assets"
}

output "game_assets_storage_account_id" {
  value       = azurerm_storage_account.game_assets.id
  description = "ID of the storage account for game assets"
}

output "analytics_storage_account" {
  value       = azurerm_storage_account.analytics_data.name
  description = "Name of the storage account for analytics data"
}

output "analytics_container_name" {
  value       = azurerm_storage_container.analytics_data.name
  description = "Name of the container for analytics data"
}

# Managed Identity Outputs
output "player_service_identity_client_id" {
  value       = azurerm_user_assigned_identity.player_service.client_id
  description = "Client ID of the managed identity for player service"
}

output "player_service_identity_principal_id" {
  value       = azurerm_user_assigned_identity.player_service.principal_id
  description = "Principal ID of the managed identity for player service"
}

output "game_session_identity_client_id" {
  value       = azurerm_user_assigned_identity.game_session_service.client_id
  description = "Client ID of the managed identity for game session service"
}

output "game_session_identity_principal_id" {
  value       = azurerm_user_assigned_identity.game_session_service.principal_id
  description = "Principal ID of the managed identity for game session service"
}

output "analytics_identity_client_id" {
  value       = azurerm_user_assigned_identity.analytics_service.client_id
  description = "Client ID of the managed identity for analytics service"
}

output "analytics_identity_principal_id" {
  value       = azurerm_user_assigned_identity.analytics_service.principal_id
  description = "Principal ID of the managed identity for analytics service"
}

# Monitoring and Logging Outputs
output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.gaming.workspace_id
  description = "Workspace ID of the Log Analytics workspace"
}

output "log_analytics_workspace_primary_shared_key" {
  value       = azurerm_log_analytics_workspace.gaming.primary_shared_key
  description = "Primary shared key for the Log Analytics workspace"
  sensitive   = true
}

# Key Vault Outputs
output "key_vault_id" {
  value       = azurerm_key_vault.gaming.id
  description = "ID of the Key Vault for secrets management"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.gaming.vault_uri
  description = "URI of the Key Vault"
}

# Network Outputs
output "virtual_network_id" {
  value       = azurerm_virtual_network.gaming.id
  description = "ID of the virtual network"
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks.id
  description = "ID of the AKS subnet"
}

output "app_gateway_subnet_id" {
  value       = azurerm_subnet.app_gateway.id
  description = "ID of the Application Gateway subnet"
}

output "app_gateway_public_ip" {
  value       = azurerm_public_ip.app_gateway.ip_address
  description = "Public IP address of the Application Gateway"
}

# Tags for consistency
output "common_tags" {
  value = {
    Environment = var.environment
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
  description = "Common tags applied to all resources"
}
