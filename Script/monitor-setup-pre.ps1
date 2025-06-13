# monitor-setup-pre.ps1

# === Load shared environment variables ===
. "$PSScriptRoot\variables.ps1"

# === Azure login using Service Principal ===
az login --service-principal --username $clientId --password $clientSecret --tenant $tenantId | Out-Null
az account set --subscription $subscriptionId

# === Create the resource group for monitoring resources ===
az group create --name $MonitorresourceGroup --location $location

# === Step 1: Create the Log Analytics Workspace (LAW) ===
az monitor log-analytics workspace create `
  --resource-group $MonitorresourceGroup `
  --workspace-name $workspaceName `
  --location $location `
  --retention-time 30 `
  --sku PerGB2018

# Retrieve the full resource ID of the LAW
$workspaceId = az monitor log-analytics workspace show `
  --resource-group $MonitorresourceGroup `
  --workspace-name $workspaceName `
  --query id -o tsv

# === Step 2: Create the Data Collection Endpoint (DCE) ===
az monitor data-collection endpoint create `
  --name $dceName `
  --resource-group $MonitorresourceGroup `
  --location $location `
  --public-network-access "Disabled"

# === Step 3: Create the Azure Monitor Private Link Scope (AMPLS) if it doesn't exist ===
$amplsExists = az monitor private-link-scope show `
  --name $amplsName `
  --resource-group $MonitorresourceGroup `
  --query "id" -o tsv 2>$null

if (-not $amplsExists) {
    az monitor private-link-scope create `
      --name $amplsName `
      --resource-group $MonitorresourceGroup | Out-Null

    # Wait for provisioning to complete
    do {
        $state = az monitor private-link-scope show `
            --name $amplsName `
            --resource-group $MonitorresourceGroup `
            --query "provisioningState" -o tsv
        Start-Sleep -Seconds 5
    } while ($state -ne "Succeeded")
}
