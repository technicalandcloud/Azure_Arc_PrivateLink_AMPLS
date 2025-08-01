#  monitor-setup-post.ps1 


. "$PSScriptRoot\variables.ps1"


az login --service-principal --username $clientId --password $clientSecret --tenant $tenantId | Out-Null
az account set --subscription $subscriptionId



Write-Host "Retrieving Log Analytics Workspace ID"
$workspaceId = az monitor log-analytics workspace show `
  --resource-group $monitorResourceGroup `
  --workspace-name $workspaceName `
  --query id -o tsv


Write-Host "Creating Private Endpoint for Azure Monitor Private Link Scope (AMPLS)"
$subnetId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$azureVnetName/subnets/$azureSubnetName"

az network private-endpoint create `
  --name $peName `
  --resource-group $monitorResourceGroup `
  --location $location `
  --subnet $subnetId `
  --private-connection-resource-id "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Insights/privateLinkScopes/$amplsName" `
  --group-id "azuremonitor" `
  --connection-name $connectionName


Write-Host "Creating Private DNS Zones"
az network private-dns zone create `
  --resource-group $monitorResourceGroup `
  --name $dnsZoneName

az network private-dns zone create `
  --resource-group $monitorResourceGroup `
  --name $dnsZoneNamelaw 


Write-Host "Linking monitor.azure.com DNS Zone to the on-prem VNet"
az network private-dns link vnet create `
  --resource-group $monitorResourceGroup `
  --zone-name $dnsZoneName `
  --name "${onPremVnetName}-monitor-dns-link" `
  --virtual-network "/subscriptions/$subscriptionId/resourceGroups/$onPremResourceGroup/providers/Microsoft.Network/virtualNetworks/$onPremVnetName" `
  --registration-enabled false

Write-Host "Linking ods.opinsights.azure.com DNS Zone to the Azure VNet"
az network private-dns link vnet create `
  --resource-group $monitorResourceGroup `
  --zone-name $dnsZoneNamelaw `
  --name "${onPremVnetName}-ods-dns-link" `
  --virtual-network "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$azureVnetName" `
  --registration-enabled false


Write-Host "Checking if DNS Zone Group already exists for $peName"
$existingGroup = az network private-endpoint dns-zone-group show `
  --resource-group $monitorResourceGroup `
  --endpoint-name $peName `
  --name $dnsZoneGroupName `
  --only-show-errors `
  --output none 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deleting existing DNS Zone Group $dnsZoneGroupName"
    az network private-endpoint dns-zone-group delete `
      --resource-group $monitorResourceGroup `
      --endpoint-name $peName `
      --name $dnsZoneGroupName
}

Write-Host "Creating DNS Zone Group with monitor.azure.com"
az network private-endpoint dns-zone-group create `
  --resource-group $monitorResourceGroup `
  --endpoint-name $peName `
  --name $dnsZoneGroupName `
  --zone-name $dnsZoneName `
  --private-dns-zone "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Network/privateDnsZones/$dnsZoneName"

Write-Host "Adding ods.opinsights.azure.com DNS Zone to the same group"
az network private-endpoint dns-zone-group add `
   --endpoint-name $peName `
   --resource-group $monitorResourceGroup `
   --name $dnsZoneGroupName `
   --zone-name "ods-zone" `
   --private-dns-zone "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Network/privateDnsZones/$dnsZoneNamelaw"


Write-Host "Linking Log Analytics Workspace to AMPLS"
az monitor private-link-scope scoped-resource create `
  --name "law-link" `
  --resource-group $monitorResourceGroup `
  --scope-name $amplsName `
  --linked-resource "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$workspaceName"


Write-Host "Linking DCE to AMPLS"
az monitor private-link-scope scoped-resource create `
  --name "dce-link" `
  --resource-group $monitorResourceGroup `
  --scope-name $amplsName `
  --linked-resource "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Insights/dataCollectionEndpoints/$dceName"

Write-Host "`nPost-deployment configuration completed successfully."


$dceRecords = @()
$records = az network private-dns record-set a list `
  --zone-name $dnsZoneName `
  --resource-group $monitorResourceGroup `
  | ConvertFrom-Json

foreach ($record in $records) {
    foreach ($ip in $record.arecords) {
        $dceRecords += @{
            fqdn = "$($record.name).$dnsZoneName"
            ip   = $ip.ipv4Address
        }
    }
}


$odsRecords = @()
$dnsRecords = az network private-dns record-set a list `
  --zone-name $dnsZoneNamelaw `
  --resource-group $monitorResourceGroup `
  | ConvertFrom-Json

foreach ($record in $dnsRecords) {
    foreach ($ip in $record.arecords) {
        $odsRecords += @{
            fqdn = "$($record.name).$dnsZoneNamelaw"
            ip   = $ip.ipv4Address
        }
    }
}





$psScript  = ""

# Add DCE records to hosts
foreach ($record in $dceRecords) {
    $cleanFqdn = $record.fqdn.TrimEnd('.').Replace('.privatelink','')
    if ($record.ip) {
        Write-Host "Adding DCE entry: $cleanFqdn -> $($record.ip)"
        $psScript += "Add-Content -Path 'C:\\Windows\\System32\\drivers\\etc\\hosts' -Value '$($record.ip) $cleanFqdn'; "
    }
}

# Add ODS records to hosts
foreach ($record in $odsRecords) {
    $cleanFqdn = $record.fqdn.TrimEnd('.').Replace('.privatelink','')
    if ($record.ip) {
        Write-Host "Adding ODS entry: $cleanFqdn -> $($record.ip)"
        $psScript += "Add-Content -Path 'C:\\Windows\\System32\\drivers\\etc\\hosts' -Value '$($record.ip) $cleanFqdn'; "
    }
}

# Add monitor.azure.com records from PE
foreach ($config in $dnsConfigs) {
    foreach ($ip in $config.ipAddresses) {
        $cleanFqdn = $config.fqdn.TrimEnd('.')
        Write-Host " Adding Monitor entry: $cleanFqdn -> $ip"
        $psScript += "Add-Content -Path 'C:\\Windows\\System32\\drivers\\etc\\hosts' -Value '$ip $cleanFqdn'; "
    }
}

# Display hosts content at the end for verification
$psScript += " Get-Content 'C:\\Windows\\System32\\drivers\\etc\\hosts' "


Write-Host " Updating hosts file on Windows VM: ArcDemo-VM"
az vm run-command invoke `
  --command-id RunPowerShellScript `
  --name ArcDemo-VM `
  --resource-group Arc-OnPrem-RG `
  --scripts "$psScript"

Write-Host "Hosts file successfully updated on Windows VM"


Write-Host "`Post-deployment configuration completed successfully, with DNS records created and /etc/hosts updated on arc-demo."
