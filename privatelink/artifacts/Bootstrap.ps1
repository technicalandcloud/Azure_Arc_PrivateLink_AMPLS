param (
    [string]$appId,
    [string]$password,
    [string]$tenantId,
    [string]$resourceGroup,
    [string]$subscriptionId,
    [string]$Location,
    [string]$PEname,
    [string]$adminUsername,
    [string]$PLscope
)

[System.Environment]::SetEnvironmentVariable('appId', $appId,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('password', $password,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('tenantId', $tenantId,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('resourceGroup', $resourceGroup,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('subscriptionId', $subscriptionId,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('Location', $location,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('PEname', $PEname,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('adminUsername', $adminUsername,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('PLscope', $PLscope,[System.EnvironmentVariableTarget]::Machine)

# Creating Log File
New-Item -Path "C:\" -Name "Temp" -ItemType "directory" -Force
Start-Transcript -Path C:\Temp\LogonScript.log

# Install Azure CLI (without Chocolatey)
$cliInstaller = "$env:TEMP\azure-cli.msi"
Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindows" -OutFile $cliInstaller -UseBasicParsing
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$cliInstaller`" /qn"
Remove-Item $cliInstaller

# Install Az PowerShell module
Install-PackageProvider -Name NuGet -Force -Scope AllUsers
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name Az -Force -AllowClobber

# Download and run Arc onboarding script
Invoke-WebRequest ("https://raw.githubusercontent.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS/refs/heads/main/privatelink/artifacts/installArcAgent.ps1") -OutFile C:\Temp\installArcAgent.ps1

# Disable Microsoft Edge sidebar
$RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$Name         = 'HubsSidebarEnabled'
$Value        = '00000000'
If (-NOT (Test-Path $RegistryPath)) {
  New-Item -Path $RegistryPath -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force

# Disable Microsoft Edge first-run Welcome screen
$RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$Name         = 'HideFirstRunExperience'
$Value        = '00000001'
If (-NOT (Test-Path $RegistryPath)) {
  New-Item -Path $RegistryPath -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force

# Creating LogonScript Windows Scheduled Task
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument 'C:\Temp\installArcAgent.ps1'
Register-ScheduledTask -TaskName "LogonScript" -Trigger $Trigger -User "${adminUsername}" -Action $Action -RunLevel "Highest" -Force

# Disabling Windows Server Manager Scheduled Task
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask

# Clean up Bootstrap.log
Stop-Transcript
$logSuppress = Get-Content C:\Temp\LogonScript.log -Force | Where { $_ -notmatch "Host Application: powershell.exe" }
$logSuppress | Set-Content C:\Temp\LogonScript.log -Force
