# modules/monitoring/main.tf

# ============================================
# LOG ANALYTICS WORKSPACE
# ============================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# ============================================
# DATA COLLECTION ENDPOINT (DCE)
# ============================================

resource "azurerm_monitor_data_collection_endpoint" "main" {
  name                          = "${var.name_prefix}-dce"
  location                      = var.location
  resource_group_name           = var.rg_name
  public_network_access_enabled = false
  tags                          = var.tags
}

# ============================================
# DATA COLLECTION RULE (DCR)
# ============================================

resource "azurerm_monitor_data_collection_rule" "main" {
  name                        = "${var.name_prefix}-dcr"
  location                    = var.location
  resource_group_name         = var.rg_name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.main.id
  tags                        = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event", "Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(*)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(*)\\% Free Space",
        "\\LogicalDisk(*)\\Free Megabytes",
      ]
      name = "perfCounters"
    }

    windows_event_log {
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "System!*[System[(Level=1 or Level=2 or Level=3)]]",
      ]
      name = "windowsEvents"
    }
  }
}

# ============================================
# AZURE MONITOR PRIVATE LINK SCOPE (AMPLS)
# ============================================

resource "azurerm_monitor_private_link_scope" "main" {
  name                = "${var.name_prefix}-ampls"
  resource_group_name = var.rg_name
  tags                = var.tags
}

# Lier le Log Analytics Workspace à l'AMPLS
resource "azurerm_monitor_private_link_scoped_service" "law" {
  name                = "law-link"
  resource_group_name = var.rg_name
  scope_name          = azurerm_monitor_private_link_scope.main.name
  linked_resource_id  = azurerm_log_analytics_workspace.main.id
}

# Lier le DCE à l'AMPLS
resource "azurerm_monitor_private_link_scoped_service" "dce" {
  name                = "dce-link"
  resource_group_name = var.rg_name
  scope_name          = azurerm_monitor_private_link_scope.main.name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.main.id
}

# ============================================
# PRIVATE DNS ZONES POUR AZURE MONITOR
# ============================================

resource "azurerm_private_dns_zone" "monitor" {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "oms" {
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "ods" {
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "agentsvc" {
  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.rg_name
  tags                = var.tags
}

# ============================================
# PRIVATE ENDPOINT POUR AMPLS
# ============================================

resource "azurerm_private_endpoint" "ampls" {
  name                = "${var.name_prefix}-ampls-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.azure_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "ampls-connection"
    private_connection_resource_id = azurerm_monitor_private_link_scope.main.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "ampls-dns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor.id,
      azurerm_private_dns_zone.oms.id,
      azurerm_private_dns_zone.ods.id,
      azurerm_private_dns_zone.agentsvc.id,
      azurerm_private_dns_zone.blob.id,
    ]
  }

  depends_on = [
    azurerm_monitor_private_link_scoped_service.law,
    azurerm_monitor_private_link_scoped_service.dce
  ]
}

# ============================================
# DNS ZONE LINKS - VERS LES DEUX VNETS
# ============================================

locals {
  dns_zones = {
    monitor  = azurerm_private_dns_zone.monitor
    oms      = azurerm_private_dns_zone.oms
    ods      = azurerm_private_dns_zone.ods
    agentsvc = azurerm_private_dns_zone.agentsvc
    blob     = azurerm_private_dns_zone.blob
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "onprem" {
  for_each = local.dns_zones

  name                  = "${each.key}-onprem-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = var.onprem_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "azure" {
  for_each = local.dns_zones

  name                  = "${each.key}-azure-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = var.azure_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}