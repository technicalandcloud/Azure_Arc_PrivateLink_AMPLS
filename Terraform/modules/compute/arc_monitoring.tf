# ==================== WAIT FOR ARC ONBOARDING ====================
resource "time_sleep" "wait_for_arc_bootstrap" {
  count = var.enable_monitoring ? 1 : 0

  create_duration = "2m"

  depends_on = [
    azurerm_virtual_machine_run_command.arc_onboard
  ]
}

# ==================== AZURE MONITOR AGENT EXTENSION ====================
resource "azurerm_arc_machine_extension" "ama" {
  count = var.enable_monitoring ? 1 : 0

  name                      = "AzureMonitorWindowsAgent"
  location                  = var.location
  arc_machine_id            = "/subscriptions/${var.arc_subscription_id}/resourceGroups/${var.arc_rg_name}/providers/Microsoft.HybridCompute/machines/${var.name_prefix}-vm"
  publisher                 = "Microsoft.Azure.Monitor"
  type                      = "AzureMonitorWindowsAgent"
  type_handler_version      = "1.0"
  automatic_upgrade_enabled = true

  depends_on = [
    time_sleep.wait_for_arc_bootstrap
  ]

  timeouts {
    create = "45m"
    update = "30m"
  }

  lifecycle {
    ignore_changes = [settings]
  }
}

# ==================== DATA COLLECTION RULE ASSOCIATION ====================
resource "azurerm_monitor_data_collection_rule_association" "dcr" {
  count = var.enable_monitoring ? 1 : 0

  name                    = "dcr-association"
  target_resource_id      = "/subscriptions/${var.arc_subscription_id}/resourceGroups/${var.arc_rg_name}/providers/Microsoft.HybridCompute/machines/${var.name_prefix}-vm"
  data_collection_rule_id = var.dcr_id

  depends_on = [azurerm_arc_machine_extension.ama]
}

# ==================== DATA COLLECTION ENDPOINT ASSOCIATION ====================
resource "azurerm_monitor_data_collection_rule_association" "dce" {
  count = var.enable_monitoring ? 1 : 0

  name                        = "configurationAccessEndpoint"
  target_resource_id          = "/subscriptions/${var.arc_subscription_id}/resourceGroups/${var.arc_rg_name}/providers/Microsoft.HybridCompute/machines/${var.name_prefix}-vm"
  data_collection_endpoint_id = var.dce_id

  depends_on = [azurerm_arc_machine_extension.ama]
}