# modules/compute/outputs.tf

output "vm_id" {
  value = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.main.name
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}

output "bastion_dns_name" {
  value = azurerm_bastion_host.main.dns_name
}

output "bastion_public_ip" {
  value = azurerm_public_ip.bastion.ip_address
}