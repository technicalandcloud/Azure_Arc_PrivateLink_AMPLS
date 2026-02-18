# ============================================
# VNETS
# ============================================

resource "azurerm_virtual_network" "onprem" {
  name                = "${var.name_prefix}-onprem-vnet"
  address_space       = [var.onprem_vnet_address_space]
  location            = var.location
  resource_group_name = var.onprem_rg_name
  tags                = var.tags
}

resource "azurerm_virtual_network" "azure" {
  name                = "${var.name_prefix}-azure-vnet"
  address_space       = [var.azure_vnet_address_space]
  location            = var.location
  resource_group_name = var.azure_rg_name
  tags                = var.tags
}

# ============================================
# SUBNETS - ONPREM
# ============================================

resource "azurerm_subnet" "onprem_default" {
  name                 = "default"
  resource_group_name  = var.onprem_rg_name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = [cidrsubnet(var.onprem_vnet_address_space, 8, 1)]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.onprem_rg_name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = [cidrsubnet(var.onprem_vnet_address_space, 11, 16)]
}

resource "azurerm_subnet" "onprem_gateway" {
  count                = var.enable_vpn_gateway ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = var.onprem_rg_name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = [cidrsubnet(var.onprem_vnet_address_space, 10, 12)]
}

# ============================================
# SUBNETS - AZURE
# ============================================

resource "azurerm_subnet" "azure_default" {
  name                 = "default"
  resource_group_name  = var.azure_rg_name
  virtual_network_name = azurerm_virtual_network.azure.name
  address_prefixes     = [cidrsubnet(var.azure_vnet_address_space, 8, 1)]
}

resource "azurerm_subnet" "azure_gateway" {
  count                = var.enable_vpn_gateway ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = var.azure_rg_name
  virtual_network_name = azurerm_virtual_network.azure.name
  address_prefixes     = [cidrsubnet(var.azure_vnet_address_space, 10, 0)]
}

# ============================================
# NSG - SÉCURISÉ
# ============================================

resource "azurerm_network_security_group" "onprem" {
  name                = "${var.name_prefix}-onprem-nsg"
  location            = var.location
  resource_group_name = var.onprem_rg_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "allow_bastion_rdp" {
  name                        = "AllowBastionRDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = azurerm_subnet.bastion.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = var.onprem_rg_name
  network_security_group_name = azurerm_network_security_group.onprem.name
}


resource "azurerm_network_security_rule" "allow_azure_vnet" {
  name                        = "AllowAzureVNet"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.azure_vnet_address_space
  destination_address_prefix  = "*"
  resource_group_name         = var.onprem_rg_name
  network_security_group_name = azurerm_network_security_group.onprem.name
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.onprem_rg_name
  network_security_group_name = azurerm_network_security_group.onprem.name
}

resource "azurerm_subnet_network_security_group_association" "onprem" {
  subnet_id                 = azurerm_subnet.onprem_default.id
  network_security_group_id = azurerm_network_security_group.onprem.id
}

# ============================================
# VPN GATEWAYS (optionnel)
# ============================================

resource "azurerm_public_ip" "onprem_gw" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "${var.name_prefix}-onprem-gw-pip"
  location            = var.location
  resource_group_name = var.onprem_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "azure_gw" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "${var.name_prefix}-azure-gw-pip"
  location            = var.location
  resource_group_name = var.azure_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "onprem" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "${var.name_prefix}-onprem-gw"
  location            = var.location
  resource_group_name = var.onprem_rg_name
  tags                = var.tags

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.onprem_gw[0].id
    subnet_id                     = azurerm_subnet.onprem_gateway[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_gateway" "azure" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "${var.name_prefix}-azure-gw"
  location            = var.location
  resource_group_name = var.azure_rg_name
  tags                = var.tags

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.azure_gw[0].id
    subnet_id                     = azurerm_subnet.azure_gateway[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_gateway_connection" "azure_to_onprem" {
  count                           = var.enable_vpn_gateway ? 1 : 0
  name                            = "${var.name_prefix}-azure-to-onprem"
  location                        = var.location
  resource_group_name             = var.azure_rg_name
  tags                            = var.tags

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.azure[0].id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem[0].id
  shared_key                      = var.vpn_shared_key
}

resource "azurerm_virtual_network_gateway_connection" "onprem_to_azure" {
  count                           = var.enable_vpn_gateway ? 1 : 0
  name                            = "${var.name_prefix}-onprem-to-azure"
  location                        = var.location
  resource_group_name             = var.onprem_rg_name
  tags                            = var.tags

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.onprem[0].id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.azure[0].id
  shared_key                      = var.vpn_shared_key
}

# Alternative sans VPN: VNet Peering (moins coûteux pour lab)
resource "azurerm_virtual_network_peering" "onprem_to_azure" {
  count                     = var.enable_vpn_gateway ? 0 : 1
  name                      = "onprem-to-azure"
  resource_group_name       = var.onprem_rg_name
  virtual_network_name      = azurerm_virtual_network.onprem.name
  remote_virtual_network_id = azurerm_virtual_network.azure.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "azure_to_onprem" {
  count                     = var.enable_vpn_gateway ? 0 : 1
  name                      = "azure-to-onprem"
  resource_group_name       = var.azure_rg_name
  virtual_network_name      = azurerm_virtual_network.azure.name
  remote_virtual_network_id = azurerm_virtual_network.onprem.id
  allow_forwarded_traffic   = true
}

# ============================================
# ARC PRIVATE LINK SCOPE
# ============================================

resource "azapi_resource" "arc_private_link_scope" {
  type      = "Microsoft.HybridCompute/privateLinkScopes@2022-12-27"
  name      = "${var.name_prefix}-arc-pls"
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.azure_rg_name}"
  tags      = var.tags

  body = {
    properties = {
      publicNetworkAccess = "Disabled"
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_private_endpoint" "arc" {
  name                = "${var.name_prefix}-arc-pe"
  location            = var.location
  resource_group_name = var.azure_rg_name
  subnet_id           = azurerm_subnet.azure_default.id
  tags                = var.tags

  private_service_connection {
    name                           = "arc-connection"
    private_connection_resource_id = azapi_resource.arc_private_link_scope.id
    subresource_names              = ["hybridCompute"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "arc-dns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.his.id,
      azurerm_private_dns_zone.guestconfig.id,
      azurerm_private_dns_zone.kubeconfig.id,
    ]
  }
}

# ============================================
# PRIVATE DNS ZONES
# ============================================

resource "azurerm_private_dns_zone" "his" {
  name                = "privatelink.his.arc.azure.com"
  resource_group_name = var.azure_rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "guestconfig" {
  name                = "privatelink.guestconfiguration.azure.com"
  resource_group_name = var.azure_rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "kubeconfig" {
  name                = "privatelink.dp.kubernetesconfiguration.azure.com"
  resource_group_name = var.azure_rg_name
  tags                = var.tags
}

# DNS Zone Links
resource "azurerm_private_dns_zone_virtual_network_link" "his_onprem" {
  name                  = "his-onprem-link"
  resource_group_name   = var.azure_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.his.name
  virtual_network_id    = azurerm_virtual_network.onprem.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "guestconfig_onprem" {
  name                  = "guestconfig-onprem-link"
  resource_group_name   = var.azure_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.guestconfig.name
  virtual_network_id    = azurerm_virtual_network.onprem.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kubeconfig_onprem" {
  name                  = "kubeconfig-onprem-link"
  resource_group_name   = var.azure_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.kubeconfig.name
  virtual_network_id    = azurerm_virtual_network.onprem.id
  registration_enabled  = false
  tags                  = var.tags
}