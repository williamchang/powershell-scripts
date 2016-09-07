<#

Microsoft PowerShell

Restart Ethernet Device
Created by William Chang

Created: 2012-02-21
Modified: 2016-09-05

PowerShell Examples:
powershell.exe Get-Host
powershell.exe Get-ExecutionPolicy
powershell.exe Get-ExecutionPolicy -List
powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
powershell.exe -File .\Restart_Computer_Ethernet_Device.ps1.ps1
powershell.exe -File C:\Temp\Restart_Computer_Ethernet_Device.ps1.ps1

Windows Shortcut:
Target
%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File C:\Restart_Ethernet_Device.ps1

#>

$currentScriptName = 'Restart_Ethernet_Device'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

function Invoke-Main {
    $wmiDevice = Get-WmiObject -Class 'Win32_NetworkAdapter' -Filter 'Name LIKE ''%82578DC%'''
    if($wmiDevice -ne $Null) {
        Start-Sleep -Seconds 8

        Write-Output ('')
        Write-Output ('Found Ethernet Device: {0}' -f $wmiDevice.Name)
        Write-Output ('')

        $wmiDevice.Disable() | Out-Null

        Write-Output ('')
        Write-Output ('Disabled Ethernet Device')
        Write-Output ('')

        Start-Sleep -Seconds 4

        $wmiDevice.Enable() | Out-Null

        Write-Output ('')
        Write-Output ('Enabled Ethernet Device')
        Write-Output ('')
    }
}

Invoke-Main

