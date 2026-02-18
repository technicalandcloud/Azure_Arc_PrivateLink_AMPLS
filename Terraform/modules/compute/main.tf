# modules/compute/main.tf

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
}

resource "azurerm_virtual_machine_run_command" "arc_onboard" {
  name               = "ArcOnboarding"
  location           = var.location
  virtual_machine_id = azurerm_windows_virtual_machine.main.id

  source {
    script = <<-EOF
      Start-Transcript -Path "C:\Temp\ArcOnboard.log" -Force
      New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null

      # 1. Bloquer IMDS pour permettre Arc sur une VM Azure
      New-NetFirewallRule -Name BlockAzureIMDS -DisplayName "Block access to Azure IMDS" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress 169.254.169.254

      # 2. Installer Azure CLI
      $ProgressPreference = 'SilentlyContinue'
      Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile C:\Temp\AzureCLI.msi
      Start-Process msiexec.exe -ArgumentList '/i', 'C:\Temp\AzureCLI.msi', '/quiet', '/norestart' -Wait
      $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')

      # 3. Login Azure CLI
      az login --service-principal -u "${var.arc_client_id}" -p "${var.arc_client_secret}" --tenant "${var.arc_tenant_id}"
      az account set -s "${var.arc_subscription_id}"

      # 4. Résoudre les DNS du Private Endpoint dans le fichier hosts
      $file = "C:\Windows\System32\drivers\etc\hosts"
      $pe = az network private-endpoint dns-zone-group list --endpoint-name "${var.arc_pe_name}" --resource-group "${var.arc_rg_name}" -o json | ConvertFrom-Json
      $hostfile = Get-Content $file
      foreach ($zone in $pe[0].privateDnsZoneConfigs) {
        foreach ($record in $zone.recordSets) {
          $fqdn = $record.fqdn -replace '\.privatelink', ''
          $ip = $record.ipAddresses[0]
          $hostfile += "$ip $fqdn"
          Write-Host "DNS: $ip -> $fqdn"
        }
      }
      Set-Content -Path $file -Value $hostfile -Force

      # 5. Télécharger et installer l'agent Arc
      Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile C:\Temp\AzureConnectedMachineAgent.msi
      Start-Process msiexec.exe -ArgumentList '/i', 'C:\Temp\AzureConnectedMachineAgent.msi', '/quiet', '/norestart' -Wait
      Start-Sleep -Seconds 15

      # 6. Connecter à Azure Arc
      & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect `
        --service-principal-id "${var.arc_client_id}" `
        --service-principal-secret "${var.arc_client_secret}" `
        --tenant-id "${var.arc_tenant_id}" `
        --subscription-id "${var.arc_subscription_id}" `
        --resource-group "${var.arc_rg_name}" `
        --location "${var.location}" `
        --private-link-scope "${var.arc_pls_id}" `
        --correlation-id ([guid]::NewGuid().ToString())

      Write-Host "Exit code: $LASTEXITCODE"
      & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" show

      Stop-Transcript
    EOF
  }

  timeouts {
    create = "60m"
    delete = "30m"
  }
}

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