# monitor-setup-pre.ps1

# === Load shared environment variables ===
. "$PSScriptRoot\variables.ps1"

# === Azure login using Service Principal ===
az login --service-principal --username $clientId --password $clientSecret --tenant $tenantId | Out-Null
az account set --subscription $subscriptionId

# === Create the resource group for monitoring resources ===
az group create --name $monitorResourceGroup --location $location

# === Step 1: Create the Log Analytics Workspace (LAW) ===
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

# === Step 2: Create the Data Collection Endpoint (DCE) ===
az monitor data-collection endpoint create `
  --name $dceName `
  --resource-group $monitorResourceGroup `
  --location $location `
  --public-network-access "Disabled"

# === Step 3: Create the Azure Monitor Private Link Scope (AMPLS) ===
az monitor private-link-scope create `
  --name $amplsName `
  --resource-group $monitorResourceGroup
