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
    Write-Host "Error during integration ARC PE"
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
    Write-Host "Error during integration AMPLS PE"
}

try {
    $hostfile = Get-Content $file
    $hostfile += "$gisIP $gisfqdn"
    $hostfile += "$hisIP $hisfqdn"
    $hostfile += "$agentIp $agentfqdn"
    $hostfile += "$gasIp $gasfqdn"
    $hostfile += "$dpIp $dpfqdn"
    Set-Content -Path $file -Value $hostfile -Force
    Write-Host "File host update"
} catch {
    Write-Host "Error During integration Host"
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

# Deploy AMA, DCR and association via ARM template
Start-Sleep -Seconds 15

$templatePath = "C:\Temp\arc-ama-deployment.json"
$templateJson = @'
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workspaceName": {
            "type": "string",
            "metadata": {
                "description": "Name of the workspace."
            }
        },
        "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
                "description": "Specifies the location in which to create the workspace."
            }
        },
        "dataRetention": {
            "type": "int",
            "defaultValue": 30,
            "minValue": 7,
            "maxValue": 730,
            "metadata": {
                "description": "Number of days to retain data."
            }
        },
        "vmName": {
            "type": "string",
            "metadata": {
                "description": "Windows Azure Arc-enabled server where the AMA extension will be installed."
            }
        },
        "dcrName": {
            "type": "string",
            "minLength": 1,
            "defaultValue": "dcr-windows-jumpstart",
            "metadata": {
                "description": "Name of the data collection rule"
            }
        },
        "associationName": {
            "type": "string",
            "defaultValue": "my-windows-jumpstart-dcr",
            "metadata": {
                "description": "The name of the association."
            }
        }
    },
    "variables": {
        "workspaceResourceId": "[resourceId('Microsoft.OperationalInsights/workspaces/', parameters('workspaceName'))]"
    },
    "resources": [
        {
            "apiVersion": "2020-08-01",
            "type": "Microsoft.OperationalInsights/workspaces",
            "name": "[parameters('workspaceName')]",
            "location": "[parameters('location')]",
            "properties": {
                "sku": {
                    "Name": "pergb2018"
                },
                "retentionInDays": "[parameters('dataRetention')]",
                "features": {
                    "searchVersion": 1,
                    "legacy": 0
                }
            },
            "resources": []
        },
        {
            "type": "Microsoft.HybridCompute/machines/extensions",
            "apiVersion": "2021-12-10-preview",
            "name": "[format('{0}/AzureMonitorWindowsAgent', parameters('vmName'))]",
            "location": "[parameters('location')]",
            "properties": {
                "publisher": "Microsoft.Azure.Monitor",
                "type": "AzureMonitorWindowsAgent",
                "autoUpgradeMinorVersion": true
            }
        },
        {
            "type": "Microsoft.Insights/dataCollectionRules",
            "apiVersion": "2021-04-01",
            "name": "[parameters('dcrName')]",
            "location": "[parameters('location')]",
            "kind": "Windows",
            "dependsOn": [
                "[variables('workspaceResourceId')]"
            ],
            "properties": {
                "dataSources": {
                    "performanceCounters": [
                        {
                            "streams": [
                                "Microsoft-Perf"
                            ],
                            "samplingFrequencyInSeconds": 60,
                            "counterSpecifiers": [
                                "\\Processor Information(_Total)\\% Processor Time",
                                "\\Processor Information(_Total)\\% Privileged Time",
                                "\\Processor Information(_Total)\\% User Time",
                                "\\Processor Information(_Total)\\Processor Frequency",
                                "\\System\\Processes",
                                "\\Process(_Total)\\Thread Count",
                                "\\Process(_Total)\\Handle Count",
                                "\\System\\System Up Time",
                                "\\System\\Context Switches/sec",
                                "\\System\\Processor Queue Length",
                                "\\Memory\\% Committed Bytes In Use",
                                "\\Memory\\Available Bytes",
                                "\\Memory\\Committed Bytes",
                                "\\Memory\\Cache Bytes",
                                "\\Memory\\Pool Paged Bytes",
                                "\\Memory\\Pool Nonpaged Bytes",
                                "\\Memory\\Pages/sec",
                                "\\Memory\\Page Faults/sec",
                                "\\Process(_Total)\\Working Set",
                                "\\Process(_Total)\\Working Set - Private",
                                "\\LogicalDisk(_Total)\\% Disk Time",
                                "\\LogicalDisk(_Total)\\% Disk Read Time",
                                "\\LogicalDisk(_Total)\\% Disk Write Time",
                                "\\LogicalDisk(_Total)\\% Idle Time",
                                "\\LogicalDisk(_Total)\\Disk Bytes/sec",
                                "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
                                "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
                                "\\LogicalDisk(_Total)\\Disk Transfers/sec",
                                "\\LogicalDisk(_Total)\\Disk Reads/sec",
                                "\\LogicalDisk(_Total)\\Disk Writes/sec",
                                "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
                                "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
                                "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
                                "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
                                "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
                                "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
                                "\\LogicalDisk(_Total)\\% Free Space",
                                "\\LogicalDisk(_Total)\\Free Megabytes",
                                "\\Network Interface(*)\\Bytes Total/sec",
                                "\\Network Interface(*)\\Bytes Sent/sec",
                                "\\Network Interface(*)\\Bytes Received/sec",
                                "\\Network Interface(*)\\Packets/sec",
                                "\\Network Interface(*)\\Packets Sent/sec",
                                "\\Network Interface(*)\\Packets Received/sec",
                                "\\Network Interface(*)\\Packets Outbound Errors",
                                "\\Network Interface(*)\\Packets Received Errors"
                            ],
                            "name": "windowsPerfLogsDataSource"
                        }
                    ],
                    "windowsEventLogs": [
                        {
                            "streams": [
                                "Microsoft-Event"
                            ],
                            "xPathQueries": [
                                "Application!*",
                                "System!*[System[EventID=7036]]"
                            ],
                            "name": "windowsEventLogsDataSource"
                        }
                    ]
                },
                "destinations": {
                    "logAnalytics": [
                        {
                            "workspaceResourceId": "[variables('workspaceResourceId')]",
                            "name": "la-data-destination"
                        }
                    ]
                },
                "dataFlows": [
                    {
                        "streams": [
                            "Microsoft-Perf",
                            "Microsoft-Event"
                        ],
                        "destinations": [
                            "la-data-destination"
                        ]
                    }
                ]
            }
        },
        {
            "type": "Microsoft.Insights/dataCollectionRuleAssociations",
            "apiVersion": "2019-11-01-preview",
            "scope": "[format('Microsoft.HybridCompute/machines/{0}', parameters('vmName'))]",
            "name": "[parameters('associationName')]",
            "dependsOn": [
                "[resourceId('Microsoft.Insights/dataCollectionRules/', parameters('dcrName'))]"
            ],
            "properties": {
                "description": "Association of data collection rule. Deleting this association will break the data collection for this Arc-enabled server.",
                "dataCollectionRuleId": "[resourceId('Microsoft.Insights/dataCollectionRules/', parameters('dcrName'))]"
            }
        }
    ]
}
'@
$templateJson | Out-File -FilePath $templatePath -Encoding utf8 -Force

az deployment group create `
  --resource-group $Env:resourceGroup `
  --template-file $templatePath `
  --parameters `
    workspaceName="Arc-LogAnalytics" `
    location="$Env:Location" `
    vmName="ArcDemo-VM" `
    dcrName="DCR-LogsEvents" `
    associationName="windows-jumpstart-dcr"

# Cleanup
Unregister-ScheduledTask -TaskName "LogonScript" -Confirm:$False
Stop-Process -Name powershell -Force
