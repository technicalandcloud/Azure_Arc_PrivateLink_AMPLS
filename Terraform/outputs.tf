output "resource_groups" {
  description = "Resource Groups crees"
  value = {
    for k, v in azurerm_resource_group.main : k => {
      name     = v.name
      location = v.location
    }
  }
}

output "vm_credentials" {
  description = "Credentials de la VM"
  sensitive   = true
  value = {
    username = var.vm_admin_username
    password = local.vm_password
  }
}

output "compute" {
  description = "Infos compute"
  value = {
    vm_name       = module.compute.vm_name
    vm_private_ip = module.compute.vm_private_ip
    bastion_ip    = module.compute.bastion_public_ip
  }
}

output "monitoring" {
  description = "Infos monitoring"
  value = var.enable_ampls ? {
    workspace_name = module.monitoring[0].workspace_name
    ampls_name     = module.monitoring[0].ampls_name
  } : null
}