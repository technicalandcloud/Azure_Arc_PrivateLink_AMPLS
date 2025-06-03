# Creating Log File
Start-Transcript -Path C:\Temp\ArcInstallScript.log

# Azure Login 
az login --service-principal -u $Env:appId -p $Env:password --tenant $Env:tenantId
az account set -s $Env:SubscriptionId

# Configure hosts file for Private link endpoints resolution
$file = "C:\Windows\System32\drivers\etc\hosts"
$ArcPe = "Arc-PE"
$ArcRG = "arc-azure-rg"
$AMPLSPe = "ampls-pe"
$AMPLSRG = "arc-azure-rg"

try {
    $arcDnsData = az network private-endpoint dns-zone-group list `
        --endpoint-name $ArcPe `
        --resource-group $ArcRG `
        -o json | ConvertFrom-Json

    $gisfqdn   = $arcDnsData[0].privateDnsZoneConfigs[0].recordSets[0].fqdn.Replace('.privatelink','')
    $gisIP     = $arcDnsData[0].privateDnsZoneConfigs[0].recordSets[0].ipAddresses[0]
    $hisfqdn   = $arcDnsData[0].privateDnsZoneConfigs[0].recordSets[1].fqdn.Replace('.privatelink','')
    $hisIP     = $arcDnsData[0].privateDnsZoneConfigs[0].recordSets[1].ipAddresses[0]
    $agentfqdn = $arcDnsData[0].privateDnsZoneConfigs[1].recordSets[0].fqdn.Replace('.privatelink','')
    $agentIp   = $arcDnsData[0].privateDnsZoneConfigs[1].recordSets[0].ipAddresses[0]
    $gasfqdn   = $arcDnsData[0].privateDnsZoneConfigs[1].recordSets[1].fqdn.Replace('.privatelink','')
    $gasIp     = $arcDnsData[0].privateDnsZoneConfigs[1].recordSets[1].ipAddresses[0]
    $dpfqdn    = $arcDnsData[0].privateDnsZoneConfigs[2].recordSets[0].fqdn.Replace('.privatelink','')
    $dpIp      = $arcDnsData[0].privateDnsZoneConfigs[2].recordSets[0].ipAddresses[0]
} catch {
    Write-Host "⚠️ Error during Arc PE integration: $_"
}

try {
    $amplsDnsData = az network private-endpoint dns-zone-group list `
        --endpoint-name $AMPLSPe `
        --resource-group $AMPLSRG `
        -o json | ConvertFrom-Json

    $records = $amplsDnsData[0].privateDnsZoneConfigs[0].recordSets

    for ($i = 0; $i -lt $records.Count; $i++) {
        $fqdn = $records[$i].fqdn.Replace('.privatelink','')
        $ip = $records[$i].ipAddresses[0]
        $hostfile += "$ip $fqdn"
    }
} catch {
    Write-Host "⚠️ Error during AMPLS PE integration: $_"
}

try {
    $hostfile = Get-Content $file
    $hostfile += "$gisIP $gisfqdn"
    $hostfile += "$hisIP $hisfqdn"
    $hostfile += "$agentIp $agentfqdn"
    $hostfile += "$gasIp $gasfqdn"
    $hostfile += "$dpIp $dpfqdn"

    Set-Content -Path $file -Value $hostfile -Force
    Write-Host "✅ Hosts file updated successfully."
} catch {
    Write-Host "⚠️ Error updating hosts file: $_"
}

# Configure OS to allow Arc Agent
Write-Host "🛠 Configuring OS for Azure Arc Agent"
Set-Service WindowsAzureGuestAgent -StartupType Disabled -Verbose
Stop-Service WindowsAzureGuestAgent -Force -Verbose
New-NetFirewallRule -Name BlockAzureIMDS -DisplayName "Block access to Azure IMDS" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress 169.254.169.254 -ErrorAction SilentlyContinue

# Install Azure Arc Agent
Write-Host "📦 Downloading Azure Arc Agent"
function download() {
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi
}
download

Write-Host "🚀 Installing Azure Arc Agent"
msiexec /i AzureConnectedMachineAgent.msi /qn /l*v installationlog.txt | Out-String

# Connect to Azure Arc using Private Link
Write-Host "🔗 Connecting to Azure Arc via Private Link"
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

# Cleanup
Write-Host "🧹 Cleaning up"
Unregister-ScheduledTask -TaskName "LogonScript" -Confirm:$False -ErrorAction SilentlyContinue
Stop-Process -Name powershell -Force -ErrorAction SilentlyContinue
