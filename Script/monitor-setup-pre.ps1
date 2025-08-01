# monitor-setup-pre.ps1


. "$PSScriptRoot\variables.ps1"


az login --service-principal --username $clientId --password $clientSecret --tenant $tenantId | Out-Null
az account set --subscription $subscriptionId


az group create --name $monitorResourceGroup --location $location


az monitor log-analytics workspace create `
  --resource-group $monitorResourceGroup `
  --workspace-name $workspaceName `
  --location $location `
  --retention-time 30 `
  --sku PerGB2018

# Retrieve the full resource ID of the LAW
$workspaceId = az monitor log-analytics workspace show `
  --resource-group $monitorResourceGroup `
  --workspace-name $workspaceName `
  --query id -o tsv


az monitor data-collection endpoint create `
  --name $dceName `
  --resource-group $monitorResourceGroup `
  --location $location `
  --public-network-access "Disabled"


az monitor private-link-scope create `
  --name $amplsName `
  --resource-group $monitorResourceGroup
