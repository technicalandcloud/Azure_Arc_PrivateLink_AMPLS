# ==================== NETWORK INTERFACE ====================
resource "azurerm_network_interface" "vm" {
  name                = "${var.name_prefix}-vm-nic"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# ==================== WINDOWS VM (SANS CUSTOM DATA) ====================
resource "azurerm_windows_virtual_machine" "main" {
  name                = "${var.name_prefix}-vm"
  resource_group_name = var.rg_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.vm.id]

  os_disk {
    name                 = "${var.name_prefix}-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  provision_vm_agent                                      = true
  allow_extension_operations                              = true
  bypass_platform_safety_checks_on_user_schedule_enabled = false
}

# ==================== ARC ONBOARDING VIA RUN COMMAND ====================
resource "azurerm_virtual_machine_run_command" "arc_onboard" {
  name               = "ArcOnboarding"
  location           = var.location
  virtual_machine_id = azurerm_windows_virtual_machine.main.id

  source {
    script = templatefile("${path.module}/scripts/bootstrap-arc.ps1", {
      arc_client_id       = var.arc_client_id
      arc_client_secret   = var.arc_client_secret
      arc_tenant_id       = var.arc_tenant_id
      arc_subscription_id = var.arc_subscription_id
      arc_rg_name         = var.arc_rg_name
      arc_location        = var.location
      arc_vm_name         = "${var.name_prefix}-vm"
      arc_pls_id          = var.arc_pls_id
      arc_pe_name         = var.arc_pe_name
    })
  }

  timeouts {
    create = "60m"
  }
}

# ==================== BASTION ====================
resource "azurerm_public_ip" "bastion" {
  name                = "${var.name_prefix}-bastion-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "main" {
  name                = "${var.name_prefix}-bastion"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}