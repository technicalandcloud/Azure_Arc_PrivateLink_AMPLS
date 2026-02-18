# modules/compute/arc_monitoring.tf

resource "azurerm_arc_machine_extension" "ama" {
  count          = var.enable_monitoring ? 1 : 0
  name           = "AzureMonitorWindowsAgent"
  arc_machine_id = "/subscriptions/${var.arc_subscription_id}/resourceGroups/${var.arc_rg_name}/providers/Microsoft.HybridCompute/machines/${azurerm_windows_virtual_machine.main.name}"
  location       = var.location
  type           = "AzureMonitorWindowsAgent"
  publisher      = "Microsoft.Azure.Monitor"
  tags           = var.tags

  depends_on = [azurerm_virtual_machine_run_command.arc_onboard]
}

resource "azurerm_monitor_data_collection_rule_association" "ama" {
  count                   = var.enable_monitoring ? 1 : 0
  name                    = "ama-dcr-association"
  target_resource_id      = "/subscriptions/${var.arc_subscription_id}/resourceGroups/${var.arc_rg_name}/providers/Microsoft.HybridCompute/machines/${azurerm_windows_virtual_machine.main.name}"
  data_collection_rule_id = var.dcr_id

  depends_on = [azurerm_arc_machine_extension.ama]
}

resource "azurerm_monitor_data_collection_rule_association" "dce" {
  count                       = var.enable_monitoring ? 1 : 0
  name                        = "configurationAccessEndpoint"
  target_resource_id          = "/subscriptions/${var.arc_subscription_id}/resourceGroups/${var.arc_rg_name}/providers/Microsoft.HybridCompute/machines/${azurerm_windows_virtual_machine.main.name}"
  data_collection_endpoint_id = var.dce_id

  depends_on = [azurerm_arc_machine_extension.ama]
}