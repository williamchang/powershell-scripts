<#

Microsoft PowerShell

Install Sitecore
Created by William Chang

Created: 2016-09-02
Modified: 2016-09-05

PowerShell Examples:
powershell.exe Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
powershell.exe -File .\Install_Sitecore.ps1
powershell.exe -File C:\Temp\Install_Sitecore.ps1

#>

$currentScriptName = 'Install_Sitecore'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

function Invoke-ScriptWithDotNet4 {
    if($PsVersionTable.CLRVersion.Major -lt 4) {
        $env:COMPLUS_version = 'v4.0.30319'
    }
    PowerShell .\Install_Sitecore_ConfigureFiles.ps1
}

function Invoke-Main {
    Write-Debug ('')
    Write-Debug ('PowerShell Installation Path : {0}' -f $PsHome)
    Write-Debug ('PowerShell Version : {0}' -f $PsVersionTable.PSVersion)
    Write-Debug ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
    Write-Debug ('Current Date And Time : {0}' -f $currentDateTime)
    Write-Debug ('Current Folder Path : {0}' -f $currentFolderPath)
    Write-Debug ('')

    Invoke-ScriptWithDotNet4
}

Invoke-Main
