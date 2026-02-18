output "workspace_id" {
  description = "ID du Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "Nom du Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "workspace_customer_id" {
  description = "Customer ID (Workspace ID) pour les agents"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "dce_id" {
  description = "ID du Data Collection Endpoint"
  value       = azurerm_monitor_data_collection_endpoint.main.id
}

output "dce_endpoint" {
  description = "URL d'ingestion du DCE"
  value       = azurerm_monitor_data_collection_endpoint.main.logs_ingestion_endpoint
}

output "ampls_id" {
  description = "ID de l'Azure Monitor Private Link Scope"
  value       = azurerm_monitor_private_link_scope.main.id
}

output "ampls_name" {
  description = "Nom de l'AMPLS"
  value       = azurerm_monitor_private_link_scope.main.name
}

output "dns_zones" {
  description = "DNS zones créées"
  value = {
    monitor  = azurerm_private_dns_zone.monitor.name
    oms      = azurerm_private_dns_zone.oms.name
    ods      = azurerm_private_dns_zone.ods.name
    agentsvc = azurerm_private_dns_zone.agentsvc.name
    blob     = azurerm_private_dns_zone.blob.name
  }
}

output "dcr_id" {
  description = "ID de la Data Collection Rule"
  value       = azurerm_monitor_data_collection_rule.main.id
}