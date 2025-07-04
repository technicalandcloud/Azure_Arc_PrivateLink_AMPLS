# variables.ps1

# === Service Principal Authentication (secure via environment variables) ===
$clientId       = $env:ARM_CLIENT_ID
$clientSecret   = $env:ARM_CLIENT_SECRET
$tenantId       = $env:ARM_TENANT_ID
$subscriptionId = $env:ARM_SUBSCRIPTION_ID

# === Resource Parameters ===
$resourceGroup         = "Arc-Azure-RG"
$monitorResourceGroup  = "Arc-Monitor-RG"
$onPremResourceGroup   = "Arc-OnPrem-RG"
$location              = "francecentral"
$workspaceName         = "arc-monitoring-law"
$dceName               = "arc-dce"
$dcrName               = "arc-dcr"
$amplsName             = "arc-ampls"
$peName                = "pe-arc-ampls"
$connectionName        = "ampls-connection"
$dnsZoneName           = "privatelink.monitor.azure.com"
$dnsZoneNamelaw        = "privatelink.ods.opinsights.azure.com"
$dnsZoneGroupName      = "ampls-dns-zone-group"
$azureVnetName         = "arc-azure-vnet"
$azureSubnetName       = "azure-subnet"
$onPremVnetName        = "arc-vnet"
$vmName                = "ArcDemo-VM"

# === PowerShell Error Behavior ===
$ErrorActionPreference = "Stop"
