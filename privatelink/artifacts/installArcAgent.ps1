Start-Transcript -Path C:\Temp\ArcInstallScript.log

# Azure Login
az login --service-principal -u $Env:appId -p $Env:password --tenant $Env:tenantId
az account set -s $Env:SubscriptionId

# Disable Azure Guest Agent and block IMDS
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

# Wait briefly to ensure Arc resource is ready
Start-Sleep -Seconds 30

# --- NEW: Create and associate DCR using Microsoft official script ---

Write-Host "Downloading Microsoft DCR creation script..."
$scriptPath = "C:\Temp\Add-AMASecurityEventDCR.ps1"
if (-not (Test-Path $scriptPath)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/Microsoft-Defender-for-Cloud/main/Powershell%20scripts/Create%20AMA%20DCR%20for%20Security%20Events%20collection/Add-AMASecurityEventDCR.ps1" -OutFile $scriptPath
}

Write-Host "Executing DCR setup..."
& $scriptPath `
  -DcrName "DCR-LogsEvents" `
  -ResourceGroup $env:resourceGroup `
  -SubscriptionId $env:SubscriptionId `
  -Region $env:Location `
  -LogAnalyticsWorkspaceARMId "/subscriptions/$($env:SubscriptionId)/resourceGroups/$($env:resourceGroup)/providers/Microsoft.OperationalInsights/workspaces/Arc-LogAnalytics" `
  -EventFilter AllEvents

Write-Host "✅ DCR creation, AMA installation and association complete."

# Cleanup scheduled task if present
if (Get-ScheduledTask -TaskName "LogonScript" -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName "LogonScript" -Confirm:$False
}

Stop-Transcript
exit
