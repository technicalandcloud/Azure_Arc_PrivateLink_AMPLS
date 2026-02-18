output "onprem_vnet_id" {
  value = azurerm_virtual_network.onprem.id
}

output "azure_vnet_id" {
  value = azurerm_virtual_network.azure.id
}

output "onprem_default_subnet_id" {
  value = azurerm_subnet.onprem_default.id
}

output "azure_subnet_id" {
  value = azurerm_subnet.azure_default.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}

output "arc_private_link_scope_id" {
  value = azapi_resource.arc_private_link_scope.id
}

output "arc_private_link_scope_name" {
  value = azapi_resource.arc_private_link_scope.name
}