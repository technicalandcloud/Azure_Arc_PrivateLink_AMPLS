locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  resource_groups = {
    onprem  = "${local.name_prefix}-onprem-rg"
    azure   = "${local.name_prefix}-azure-rg"
    monitor = "${local.name_prefix}-monitor-rg"
  }
}

resource "azurerm_resource_group" "main" {
  for_each = local.resource_groups
  name     = each.value
  location = var.location
  tags     = local.common_tags
}

resource "random_password" "vm_password" {
  count            = var.vm_admin_password == "" ? 1 : 0
  length           = 16
  special          = false
  min_lower        = 3
  min_upper        = 3
  min_numeric      = 3
}
resource "random_string" "vpn_shared_key" {
  length  = 32
  special = false
}

locals {
  vm_password    = var.vm_admin_password != "" ? var.vm_admin_password : random_password.vm_password[0].result
  vpn_shared_key = random_string.vpn_shared_key.result
}

module "networking" {
  source = "./modules/networking"

  name_prefix               = local.name_prefix
  location                  = var.location
  tags                      = local.common_tags
  onprem_rg_name            = azurerm_resource_group.main["onprem"].name
  azure_rg_name             = azurerm_resource_group.main["azure"].name
  onprem_vnet_address_space = var.onprem_vnet_address_space
  azure_vnet_address_space  = var.azure_vnet_address_space
  enable_vpn_gateway        = var.enable_vpn_gateway
  vpn_shared_key            = local.vpn_shared_key
  allowed_rdp_sources       = var.allowed_rdp_source_addresses
}

module "compute" {
  source = "./modules/compute"
  depends_on = [module.networking]
  # Naming & Location
  name_prefix  = local.name_prefix
  location     = var.location
  tags         = local.common_tags
  environment  = var.environment

  # Resource Group & Networking
  rg_name           = azurerm_resource_group.main["onprem"].name
  subnet_id         = module.networking.onprem_default_subnet_id
  bastion_subnet_id = module.networking.bastion_subnet_id

  # VM Configuration
  vm_size        = var.vm_size
  admin_username = var.vm_admin_username
  admin_password = local.vm_password

  # Arc Configuration
  arc_client_id       = var.arc_client_id
  arc_client_secret   = var.arc_client_secret
  arc_tenant_id       = var.tenant_id
  arc_subscription_id = var.subscription_id
  arc_rg_name         = azurerm_resource_group.main["azure"].name
  arc_pls_id          = module.networking.arc_private_link_scope_id
  arc_pe_name         = "${local.name_prefix}-arc-pe"

  # Monitoring
  enable_monitoring = var.enable_ampls
  dcr_id            = var.enable_ampls ? module.monitoring[0].dcr_id : null
  dce_id            = var.enable_ampls ? module.monitoring[0].dce_id : null
}

module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_ampls ? 1 : 0

  name_prefix        = local.name_prefix
  location           = var.location
  tags               = local.common_tags
  rg_name            = azurerm_resource_group.main["monitor"].name
  log_retention_days = var.log_retention_days
  azure_subnet_id    = module.networking.azure_subnet_id
  onprem_vnet_id     = module.networking.onprem_vnet_id
  azure_vnet_id      = module.networking.azure_vnet_id
}