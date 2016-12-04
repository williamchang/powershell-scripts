<#

Microsoft PowerShell

Install Sitecore Configure IIS
Created by William Chang

Created: 2016-09-09
Modified: 2016-09-09

#>

$currentScriptName = 'Install_Sitecore_ConfigureIIS'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

$hostsFilePath = Join-Path -Path $Env:SystemRoot -ChildPath 'System32' | Join-Path -ChildPath 'drivers' | Join-Path -ChildPath 'drivers' | Join-Path -ChildPath 'etc' | Join-Path -ChildPath 'hosts'
$cmsWebrootFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com'

function Add-MicrosoftWindowsHosts {
    param(
        [string]$HostsPath,
        [string]$Hostname
    )
    if(Test-Path -Path $HostsPath) {
        $envNewLine = [System.Environment]::NewLine
        $addLine = '{0}127.0.0.1 {1}' -f $envNewLine, $Hostname
        Add-Content -Path $HostsPath -Value $addLine
    } else {
        Write-Error 'Error in Set-MicrosoftWindowsHosts function.'
    }
}

function Get-MicrosoftIisModule {
    $moduleName = 'WebAdministration'
    $hasModule = Get-PSSnapIn | Where-Object {$_.Name -eq $moduleName}
    if($hasModule -ne $Null) {
        Add-PSSnapin -Name $moduleName
    } else {
        Import-Module -Name $moduleName
    }
}

function Add-MicrosoftIisApplicationPool {
    <#
    For debugging.

    Get-ItemProperty IIS:\AppPools\sandbox.org | Format-List
    Get-ItemProperty IIS:\AppPools\sandbox.org -name processModel
    #>

    $iisApplicationPoolName = 'sandbox.org'
    $iisApplicationPoolDotNetVersion = 'v4.0'

    $iisApplicationPoolFolderPath = 'IIS:\AppPools'
    $iisApplicationPoolPath = Join-Path -Path $iisApplicationPoolFolderPath -ChildPath $iisApplicationPoolName

    Get-ChildItem -Path $iisApplicationPoolFolderPath

    if (!(Test-Path $iisApplicationPoolName -PathType Container)) {
        <#
        Create IIS application pool.
        #>
        #New-Item –Path $iisApplicationPoolPath

        <#
        Set IIS application pool Microsoft .NET version.
        #>
        #Set-ItemProperty -Path $iisApplicationPoolPath -Name managedRuntimeVersion -Value $iisApplicationPoolDotNetVersion

        <#
        Set IIS application pool identity.

        processModel.identityType 2 : NetworkService
        processModel.identityType 4 : ApplicationPoolIdentity
        #>
        #Set-ItemProperty -Path $iisApplicationPoolPath -Name processModel.identityType -Value 2
    }
}

function Add-MicrosoftIisSite {
    $iisSiteName = 'sandbox.org'
    $iisSiteFolderPath = 'IIS:\Sites'
    $iisSitePath = Join-Path -Path $iisSiteFolderPath -ChildPath $iisSiteName

    if (!(Test-Path $iisApplicationPoolName)) {
    }
}

function Invoke-Main {
    Write-Output ('')
    Write-Output ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
    Write-Output ('Current Date And Time : {0}' -f $currentDateTime)
    Write-Output ('Current Folder Path : {0}' -f $currentFolderPath)
    Write-Output ('')

    Write-Output ('')
    Write-Output ('Hosts File Path : {0}' -f $hostsFilePath)
    Write-Output ('CMS Webroot Folder Path : {0}' -f $cmsWebrootFolderPath)
    Write-Output ('')

    Get-MicrosoftIisModule
    #Add-MicrosoftWindowsHosts -HostsPath (Join-Path -Path $currentFolderPath -ChildPath 'hosts') -Hostname 'local.sandbox1.com'
    Add-MicrosoftIisSite
}

Invoke-Main
