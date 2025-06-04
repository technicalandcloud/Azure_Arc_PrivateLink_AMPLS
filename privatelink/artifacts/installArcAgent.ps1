# Creating Log File
Start-Transcript -Path C:\Temp\ArcInstallScript.log

# Azure Login
az login --service-principal -u $Env:appId -p $Env:password --tenant $Env:tenantId
az account set -s $Env:SubscriptionId

# Hosts file path
$file = "C:\Windows\System32\drivers\etc\hosts"
$hostfile = Get-Content $file

$ArcPe = "Arc-PE"
$ArcRG = "arc-azure-rg"
$AMPLSPe = "ampls-pe"
$AMPLSRG = "arc-azure-rg"

# --- Arc Private Endpoint Entries ---
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

    $hostfile += "$gisIP $gisfqdn"
    $hostfile += "$hisIP $hisfqdn"
    $hostfile += "$agentIp $agentfqdn"
    $hostfile += "$gasIp $gasfqdn"
    $hostfile += "$dpIp $dpfqdn"
    Write-Host "Arc PE entries added"
} catch {
    Write-Host "Error during ARC PE integration"
}

# --- AMPLS Private Endpoint Entries ---
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
        Write-Host "Added: $ip $fqdn"
    }
    Write-Host "AMPLS PE entries added"
} catch {
    Write-Host "Error during AMPLS PE integration"
}


# Final update to hosts file
try {
    Set-Content -Path $file -Value $hostfile -Force
    Write-Host "Hosts file updated successfully"
} catch {
    Write-Host "Error during writing hosts file"
}


# Configure OS to allow Arc Agent
Write-Host "Configure the OS to allow Azure Arc connected machine agent to be deployed on an Azure VM"
Set-Service WindowsAzureGuestAgent -StartupType Disabled -Verbose
Stop-Service WindowsAzureGuestAgent -Force -Verbose
New-NetFirewallRule -Name BlockAzureIMDS -DisplayName "Block access to Azure IMDS" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress 169.254.169.254 

# Install Azure Arc Agent
Write-Host "Onboarding to Azure Arc"
function download() {$ProgressPreference="SilentlyContinue"; Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi}
download
msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn | Out-String

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
Unregister-ScheduledTask -TaskName "LogonScript" -Confirm:$False
Stop-Process -Name powershell -Force
