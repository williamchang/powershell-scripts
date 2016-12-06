<#

Microsoft PowerShell

Install Sitecore Configure IIS
Created by William Chang

Created: 2016-09-09
Modified: 2016-12-06

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
    param(
        [string]$Name,
        [string]$DotNetVersion
    )

    if (!$DotNetVersion) {
        $DotNetVersion = 'v4.0'
    }

    $iisApplicationPoolName = $Name
    $iisApplicationPoolDotNetVersion = $DotNetVersion
    $iisApplicationPoolFolderPath = 'IIS:\AppPools'
    $iisApplicationPoolPath = Join-Path -Path $iisApplicationPoolFolderPath -ChildPath $iisApplicationPoolName

    <#
    For debugging.

    Import-Module WebAdministration
    Get-ChildItem –Path IIS:\AppPools
    Get-ItemProperty IIS:\AppPools\sandbox.org | Format-List
    Get-ItemProperty IIS:\AppPools\sandbox.org -name 'processModel'
    #>

    Write-Debug ('')
    Write-Debug ('Application Pool Name : {0}' -f $iisApplicationPoolName)
    Write-Debug ('Application Pool .NET Version : {0}' -f $iisApplicationPoolDotNetVersion)
    Write-Debug ('Application Pool Path : {0}' -f $iisApplicationPoolPath)
    Write-Debug ('')

    if (!(Test-Path $iisApplicationPoolPath)) {
        <#
        Create IIS application pool.
        #>
        New-Item -Path $iisApplicationPoolPath

        <#
        Set IIS application pool .NET version.
        #>
        Set-ItemProperty -Path $iisApplicationPoolPath -Name 'managedRuntimeVersion' -Value $iisApplicationPoolDotNetVersion

        <#
        Set IIS application pool identity.

        processModel.identityType 2 is NetworkService
        processModel.identityType 4 is ApplicationPoolIdentity
        #>
        Set-ItemProperty -Path $iisApplicationPoolPath -Name 'processModel.identityType' -Value 2
    }
}

function Add-MicrosoftIisSite {
    param(
        [string]$Name,
        [string]$WebrootFolderPath,
        [string]$ApplicationPoolName
    )

    if (!$ApplicationPoolName) {
        $ApplicationPoolName = $Name
    }

    $iisSiteName = $Name
    $iisSiteApplicationPoolName = $ApplicationPoolName
    $iisSitePhysicalFolderPath = $WebrootFolderPath
    $iisSiteFolderPath = 'IIS:\Sites'
    $iisSitePath = Join-Path -Path $iisSiteFolderPath -ChildPath $iisSiteName

    $iisSiteBindings = @(
        @{protocol = 'http';bindingInformation = ':80:local.' + $iisSiteName}
    )

    <#
    For debugging.

    Import-Module WebAdministration
    Get-ChildItem –Path IIS:\Sites
    #>

    Write-Debug ('')
    Write-Debug ('Site Name : {0}' -f $iisSiteName)
    Write-Debug ('Site Application Pool Name : {0}' -f $iisSiteApplicationPoolName)
    Write-Debug ('Site Physical Path : {0}' -f $iisSitePhysicalFolderPath)
    Write-Debug ('Site Path : {0}' -f $iisSitePath)
    Write-Debug ('')

    if (!(Test-Path $iisSitePath)) {
        <#
        Create IIS site.
        #>
        New-Item -Path $iisSitePath -Bindings $iisSiteBindings -PhysicalPath $iisSitePhysicalFolderPath

        <#
        Set IIS site application pool.
        #>
        Set-ItemProperty -Path $iisSitePath -Name 'applicationPool' -Value $iisSiteApplicationPoolName
    }
}

function Invoke-Main {
    Write-Output ('')
    Write-Output ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
    Write-Output ('Current Date And Time : {0}' -f $currentDateTime)
    Write-Output ('Current Folder Path : {0}' -f $currentFolderPath)
    Write-Output ('Debug Preference : {0}' -f $DebugPreference)
    Write-Output ('')

    Write-Output ('')
    Write-Output ('Hosts File Path : {0}' -f $hostsFilePath)
    Write-Output ('CMS Webroot Folder Path : {0}' -f $cmsWebrootFolderPath)
    Write-Output ('')

    Get-MicrosoftIisModule
    #Add-MicrosoftWindowsHosts -HostsPath (Join-Path -Path $currentFolderPath -ChildPath 'hosts') -Hostname 'local.sandbox1.com'
    #Add-MicrosoftIisApplicationPool -Name 'site1.com'
    #Add-MicrosoftIisSite -Name 'site1.com' -WebrootFolderPath $cmsWebrootFolderPath
}

Invoke-Main
