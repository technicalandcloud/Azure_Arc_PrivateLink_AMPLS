# === monitor-setup-post.ps1 ===

# Stop execution on any error
$ErrorActionPreference = "Stop"

# === Load shared environment variables ===
. "$PSScriptRoot\variables.ps1"

# === Validate required credentials ===
if (-not $clientId -or -not $clientSecret -or -not $tenantId -or -not $subscriptionId) {
    Write-Error "❌ Missing required Service Principal credentials: clientId, clientSecret, tenantId, or subscriptionId."
    exit 1
}

# === Azure login using Service Principal ===
Write-Host "🔐 Authenticating with Azure using the Service Principal..."
az config set extension.use_dynamic_install=yes_without_prompt
az login --service-principal `
         --username $clientId `
         --password $clientSecret `
         --tenant $tenantId | Out-Null

az account set --subscription $subscriptionId

# === Retrieve Log Analytics Workspace ID ===
Write-Host "🔎 Retrieving Log Analytics Workspace ID..."
$workspaceId = az monitor log-analytics workspace show `
  --resource-group $monitorResourceGroup `
  --workspace-name $workspaceName `
  --query id -o tsv

# === Step 1: Create Private Endpoint for AMPLS ===
Write-Host "🔧 Creating Private Endpoint for Azure Monitor Private Link Scope (AMPLS)..."
$subnetId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$azureVnetName/subnets/$azureSubnetName"

az network private-endpoint create `
  --name $peName `
  --resource-group $monitorResourceGroup `
  --location $location `
  --subnet $subnetId `
  --private-connection-resource-id "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Insights/privateLinkScopes/$amplsName" `
  --group-id "azuremonitor" `
  --connection-name $connectionName

# === Step 2: Create Private DNS Zones ===
Write-Host "🌐 Creating Private DNS Zones..."
az network private-dns zone create `
  --resource-group $monitorResourceGroup `
  --name $dnsZoneName

az network private-dns zone create `
  --resource-group $monitorResourceGroup `
  --name $dnsZoneNamelaw 

# === Step 3: Link DNS Zones to VNets ===
Write-Host "🔗 Linking monitor.azure.com DNS Zone to the on-prem VNet..."
az network private-dns link vnet create `
  --resource-group $monitorResourceGroup `
  --zone-name $dnsZoneName `
  --name "${onPremVnetName}-monitor-dns-link" `
  --virtual-network "/subscriptions/$subscriptionId/resourceGroups/$onPremResourceGroup/providers/Microsoft.Network/virtualNetworks/$onPremVnetName" `
  --registration-enabled false

Write-Host "🔗 Linking ods.opinsights.azure.com DNS Zone to the Azure VNet..."
az network private-dns link vnet create `
  --resource-group $monitorResourceGroup `
  --zone-name $dnsZoneNamelaw `
  --name "${azureVnetName}-ods-dns-link" `
  --virtual-network "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$azureVnetName" `
  --registration-enabled false

# === Step 4: Recreate DNS Zone Group with both DNS Zones ===
Write-Host "🔁 Checking if DNS Zone Group already exists for $peName..."
$existingGroup = az network private-endpoint dns-zone-group show `
  --resource-group $monitorResourceGroup `
  --endpoint-name $peName `
  --name $dnsZoneGroupName `
  --only-show-errors `
  --output none 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "🧹 Deleting existing DNS Zone Group $dnsZoneGroupName..."
    az network private-endpoint dns-zone-group delete `
      --resource-group $monitorResourceGroup `
      --endpoint-name $peName `
      --name $dnsZoneGroupName
}

Write-Host "🔗 Creating DNS Zone Group with monitor.azure.com..."
az network private-endpoint dns-zone-group create `
  --resource-group $monitorResourceGroup `
  --endpoint-name $peName `
  --name $dnsZoneGroupName `
  --zone-name $dnsZoneName `
  --private-dns-zone "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Network/privateDnsZones/$dnsZoneName"

Write-Host "🔗 Adding ods.opinsights.azure.com DNS Zone to the same group..."
az network private-endpoint dns-zone-group create `
  --resource-group $monitorResourceGroup `
  --endpoint-name $peName `
  --name $dnsZoneGroupName `
  --zone-name $dnsZoneNamelaw `
  --private-dns-zone "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Network/privateDnsZones/$dnsZoneNamelaw"

# === Step 5: Link Log Analytics Workspace to AMPLS ===
Write-Host "🔗 Linking Log Analytics Workspace to AMPLS..."
az monitor private-link-scope scoped-resource create `
  --name "law-link" `
  --resource-group $monitorResourceGroup `
  --scope-name $amplsName `
  --linked-resource "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$workspaceName"

# === Step 6: Link Data Collection Endpoint (DCE) to AMPLS ===
Write-Host "🔗 Linking DCE to AMPLS..."
az monitor private-link-scope scoped-resource create `
  --name "dce-link" `
  --resource-group $monitorResourceGroup `
  --scope-name $amplsName `
  --linked-resource "/subscriptions/$subscriptionId/resourceGroups/$monitorResourceGroup/providers/Microsoft.Insights/dataCollectionEndpoints/$dceName"

Write-Host "`n✅ Post-deployment configuration completed successfully."
