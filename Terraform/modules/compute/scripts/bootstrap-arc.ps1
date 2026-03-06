#ps1_sysnative
<#
.SYNOPSIS
    Azure Arc Onboarding Bootstrap Script
    
.DESCRIPTION
    This script runs during VM first boot to onboard the machine to Azure Arc.
    Executed via custom_data (cloud-init for Windows).
#>

# ==================== CONFIGURATION ====================
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ARC_CLIENT_ID = "${arc_client_id}"
$ARC_CLIENT_SECRET = "${arc_client_secret}"
$ARC_TENANT_ID = "${arc_tenant_id}"
$ARC_SUBSCRIPTION_ID = "${arc_subscription_id}"
$ARC_RG_NAME = "${arc_rg_name}"
$ARC_LOCATION = "${arc_location}"
$ARC_VM_NAME = "${arc_vm_name}"
$ARC_PLS_ID = "${arc_pls_id}"
$ARC_PE_NAME = "${arc_pe_name}"

$LogFile = "C:\Windows\Temp\ArcBootstrap.log"

# ==================== LOGGING FUNCTION ====================
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# ==================== START BOOTSTRAP ====================
try {
    Write-Log "=========================================="
    Write-Log "AZURE ARC BOOTSTRAP - STARTING"
    Write-Log "=========================================="
    Write-Log "VM Name: $ARC_VM_NAME"
    Write-Log "Target RG: $ARC_RG_NAME"
    Write-Log "Location: $ARC_LOCATION"
    Write-Log ""

    # Create temp directory
    New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
    Write-Log "✅ Temp directory created"

    # ==================== STEP 1: BLOCK AZURE IMDS ====================
    Write-Log ""
    Write-Log "[1/7] Blocking Azure IMDS to enable Arc on Azure VM..."
    try {
        New-NetFirewallRule -Name "BlockAzureIMDS" `
            -DisplayName "Block access to Azure IMDS" `
            -Enabled True -Profile Any -Direction Outbound -Action Block `
            -RemoteAddress 169.254.169.254 -ErrorAction Stop
        Write-Log "✅ IMDS blocked successfully"
    } catch {
        Write-Log "⚠️  IMDS block rule already exists or failed: $($_.Exception.Message)"
    }

    # ==================== STEP 2: INSTALL AZURE CLI ====================
    Write-Log ""
    Write-Log "[2/7] Installing Azure CLI..."
    Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindows" -OutFile "C:\Temp\AzureCLI.msi"
    Start-Process msiexec.exe -ArgumentList "/i", "C:\Temp\AzureCLI.msi", "/quiet", "/norestart" -Wait -NoNewWindow
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Start-Sleep -Seconds 5
    Write-Log "✅ Azure CLI installed"

    # ==================== STEP 3: LOGIN WITH SERVICE PRINCIPAL ====================
    Write-Log ""
    Write-Log "[3/7] Authenticating with Azure..."
    az login --service-principal `
        -u $ARC_CLIENT_ID `
        -p $ARC_CLIENT_SECRET `
        --tenant $ARC_TENANT_ID | Out-Null
    
    az account set -s $ARC_SUBSCRIPTION_ID
    Write-Log "✅ Authenticated successfully"

    # ==================== STEP 4: CONFIGURE DNS FOR PRIVATE ENDPOINT ====================
    Write-Log ""
    Write-Log "[4/7] Configuring DNS resolution for Private Link..."
    
    $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
    $hostsContent = Get-Content $hostsFile
    
    $peConfig = az network private-endpoint dns-zone-group list `
        --endpoint-name $ARC_PE_NAME `
        --resource-group $ARC_RG_NAME `
        -o json | ConvertFrom-Json
    
    foreach ($zone in $peConfig[0].privateDnsZoneConfigs) {
        foreach ($record in $zone.recordSets) {
            $fqdn = $record.fqdn -replace '\.privatelink', ''
            $ip = $record.ipAddresses[0]
            
            if ($hostsContent -notmatch [regex]::Escape($fqdn)) {
                $hostsContent += "$ip $fqdn"
                Write-Log "  Added DNS: $ip -> $fqdn"
            }
        }
    }
    
    Set-Content -Path $hostsFile -Value $hostsContent -Force
    Write-Log "✅ DNS configured"

    # ==================== STEP 5: DOWNLOAD ARC AGENT ====================
    Write-Log ""
    Write-Log "[5/7] Downloading Azure Arc agent..."
    Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" -OutFile "C:\Temp\AzureConnectedMachineAgent.msi"
    Write-Log "✅ Agent downloaded"

    # ==================== STEP 6: INSTALL ARC AGENT ====================
    Write-Log ""
    Write-Log "[6/7] Installing Azure Arc agent..."
    Start-Process msiexec.exe -ArgumentList "/i", "C:\Temp\AzureConnectedMachineAgent.msi", "/quiet", "/norestart", "/l*v", "C:\Temp\arc-install.log" -Wait -NoNewWindow
    Start-Sleep -Seconds 15
    Write-Log "✅ Agent installed"

    # ==================== STEP 7: CONNECT TO AZURE ARC ====================
    Write-Log ""
    Write-Log "[7/7] Connecting to Azure Arc..."
    
    $azcmagent = "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe"
    
    & $azcmagent connect `
        --service-principal-id $ARC_CLIENT_ID `
        --service-principal-secret $ARC_CLIENT_SECRET `
        --tenant-id $ARC_TENANT_ID `
        --subscription-id $ARC_SUBSCRIPTION_ID `
        --resource-group $ARC_RG_NAME `
        --location $ARC_LOCATION `
        --resource-name $ARC_VM_NAME `
        --private-link-scope $ARC_PLS_ID `
        --tags "Environment=Lab,ManagedBy=Terraform,BootstrapDate=$(Get-Date -Format 'yyyy-MM-dd')" `
        --correlation-id ([guid]::NewGuid().ToString())
    
    $exitCode = $LASTEXITCODE
    Write-Log "Arc agent exit code: $exitCode"

    if ($exitCode -eq 0) {
        Write-Log "✅ Successfully connected to Azure Arc!"
        
        # Verify connection
        & $azcmagent show | Out-File -FilePath "C:\Temp\arc-status.txt"
        Write-Log ""
        Write-Log "Arc Status:"
        & $azcmagent show
    } else {
        Write-Log "❌ Arc connection failed with exit code: $exitCode"
        throw "Arc onboarding failed"
    }

    # ==================== CLEANUP ====================
    Write-Log ""
    Write-Log "Cleaning up temporary files..."
    Remove-Item "C:\Temp\AzureCLI.msi" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Temp\AzureConnectedMachineAgent.msi" -Force -ErrorAction SilentlyContinue
    Write-Log "✅ Cleanup complete"

    Write-Log ""
    Write-Log "=========================================="
    Write-Log "AZURE ARC BOOTSTRAP - COMPLETED"
    Write-Log "=========================================="
    
} catch {
    Write-Log ""
    Write-Log "=========================================="
    Write-Log "❌ BOOTSTRAP FAILED"
    Write-Log "=========================================="
    Write-Log "Error: $($_.Exception.Message)"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)"
    Write-Log ""
    exit 1
}