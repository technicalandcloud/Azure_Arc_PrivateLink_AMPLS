Start-Transcript -Path C:\Temp\ArcInstallScript.log

# Azure Login
az login --service-principal -u $Env:appId -p $Env:password --tenant $Env:tenantId
az account set -s $Env:SubscriptionId

# Configure firewall and disable Azure Guest Agent
Write-Host "Configuring OS for Azure Arc agent..."
Set-Service WindowsAzureGuestAgent -StartupType Disabled -Verbose
Stop-Service WindowsAzureGuestAgent -Force -Verbose
New-NetFirewallRule -Name BlockAzureIMDS -DisplayName "Block access to Azure IMDS" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress 169.254.169.254 

# Download and install Azure Arc agent
Write-Host "Installing Azure Arc agent..."
Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi -UseBasicParsing
msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn | Out-String

# Connect to Azure Arc
Write-Host "Connecting to Azure Arc..."
& "$Env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect `
    --resource-group $Env:resourceGroup `
    --tenant-id $Env:tenantId `
    --location $Env:Location `
    --subscription-id $Env:SubscriptionId `
    --cloud "AzureCloud" `
    --private-link-scope $Env:PLscope `
    --service-principal-id $Env:appId `
    --service-principal-secret $Env:password `
    --correlation-id "e5089a61-0238-48fd-91ef-f67846168001" `
    --tags "Project=jumpstart_azure_arc_servers"

# Wait briefly
Start-Sleep -Seconds 30

# Ensure Azure CLI 'connectedmachine' extension is installed
Write-Host "Installing Azure CLI extension: connectedmachine"
az extension add --name connectedmachine --allow-preview --only-show-errors

# Install AMA extension
$vmName = $env:COMPUTERNAME
$rgName = $env:resourceGroup
$location = $env:Location

Write-Host "Checking for AMA extension..."
try {
    $existing = az connectedmachine extension show `
        --machine-name $vmName `
        --resource-group $rgName `
        --name "AzureMonitorWindowsAgent" `
        --query "name" -o tsv 2>$null

    if (-not $existing) {
        Write-Host "Installing Azure Monitor Agent extension..."
        az connectedmachine extension create `
            --name "AzureMonitorWindowsAgent" `
            --machine-name $vmName `
            --resource-group $rgName `
            --location $location `
            --publisher "Microsoft.Azure.Monitor" `
            --type "AzureMonitorWindowsAgent" `
            --type-handler-version "1.10" `
            --settings "{}"
    } else {
        Write-Host "✅ AMA already installed."
    }
} catch {
    Write-Host "⚠️ AMA installation failed or not ready: $_"
}

# Ensure CLI extension for DCR association
Write-Host "Installing Azure CLI extension: monitor-control-service"
az extension add --name monitor-control-service --only-show-errors

# Associate to DCR
Write-Host "Associating VM to Data Collection Rule..."
try {
    $resourceId = "/subscriptions/$($env:SubscriptionId)/resourceGroups/$($env:resourceGroup)/providers/Microsoft.HybridCompute/machines/$vmName"
    $dcrId = "/subscriptions/$($env:SubscriptionId)/resourceGroups/$($env:resourceGroup)/providers/Microsoft.Insights/dataCollectionRules/DCR-LogsEvents"

az monitor data-collection rule association create `
  --resource $resourceId `
  --rule $dcrId `
  --name "dcr-assoc-$vmName" `
  --only-show-errors


    Write-Host "✅ DCR association completed."
} catch {
    Write-Host "❌ Failed to associate DCR: $_"
}

# Cleanup scheduled task if present
if (Get-ScheduledTask -TaskName "LogonScript" -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName "LogonScript" -Confirm:$False
}

# Finalize
Stop-Transcript
exit
