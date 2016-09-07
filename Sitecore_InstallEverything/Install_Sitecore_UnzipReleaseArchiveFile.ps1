<#

Microsoft PowerShell

Install Sitecore Unzip Release Archive File
Created by William Chang

Created: 2016-09-03
Modified: 2016-09-04

#>

$currentScriptName = 'Install_Sitecore_UnzipReleaseArchiveFile'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

$zipFileBaseName = 'Sitecore 8.2 rev. 160729'
$zipFileExtensionName = 'zip'
$zipFileName = '{0}.{1}' -f $zipFileBaseName, $zipFileExtensionName
$zipFilePath = Join-Path -Path $currentFolderPath -ChildPath $zipFileName

function Get-ZipPaths {
    param(
        [string]$Source
    )
    $shell = New-Object -ComObject 'Shell.Application'
    $folder = $shell.NameSpace($Source)
    $paths = @($folder.Items() | Select-Object -Property Path)
    Write-Output $paths
}

function Invoke-Unzip {
    param(
        [string]$Source,
        [string]$Target
    )
    $shell = New-Object -ComObject 'Shell.Application'
    if(!(Test-Path -Path $Target)) {
        New-Item -Path $Target -ItemType Directory | Out-Null
    }
    $sourceItems = $shell.NameSpace($Source).Items()
    $shell.NameSpace($Target).CopyHere($sourceItems)
}

function Invoke-Main {
    Write-Output ('')
    Write-Output ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
    Write-Output ('Current Date And Time : {0}' -f $currentDateTime)
    Write-Output ('Current Folder Path : {0}' -f $currentFolderPath)
    Write-Output ('')

    Write-Output ('')
    Write-Output ('Zip File Name : {0}' -f $zipFileName)
    Write-Output ('Zip File Path : {0}' -f $zipFilePath)
    Write-Output ('')
    
    Write-Output ('==========')

    $zipCmsDataSource = Join-Path -Path $zipFilePath -ChildPath $zipFileBaseName | Join-Path -ChildPath 'Data'
    $zipCmsDataTarget = Join-Path -Path $currentFolderPath -ChildPath 'site1.com.data'

    Write-Output ('')
    Write-Output ('Zip Source of CMS Data : {0}' -f $zipCmsDataSource)
    Write-Output ('Zip Target of CMS Data: {0}' -f $zipCmsDataTarget)
    Write-Output ('')

    Invoke-Unzip -Source $zipCmsDataSource -Target $zipCmsDataTarget

    Write-Output ('')
    Write-Output ('Zip Extracted CMS Data')
    Write-Output ('')
    
    Write-Output ('==========')

    $zipCmsDatabasesSource = Join-Path -Path $zipFilePath -ChildPath $zipFileBaseName | Join-Path -ChildPath 'Databases'
    $zipCmsDatabasesTarget = Join-Path -Path $currentFolderPath -ChildPath 'site1.com.databases'

    Write-Output ('')
    Write-Output ('Zip Source of CMS Databases : {0}' -f $zipCmsDatabasesSource)
    Write-Output ('Zip Target of CMS Databases : {0}' -f $zipCmsDatabasesTarget)
    Write-Output ('')

    Invoke-Unzip -Source $zipCmsDatabasesSource -Target $zipCmsDatabasesTarget

    Write-Output ('')
    Write-Output ('Zip Extracted CMS Databases')
    Write-Output ('')
    
    Write-Output ('==========')
    
    $zipCmsWebsiteSource = Join-Path -Path $zipFilePath -ChildPath $zipFileBaseName | Join-Path -ChildPath 'Website'
    $zipCmsWebsiteTarget = Join-Path -Path $currentFolderPath -ChildPath 'site1.com'

    Write-Output ('')
    Write-Output ('Zip Source of CMS Website : {0}' -f $zipCmsWebsiteSource)
    Write-Output ('Zip Target of CMS Website : {0}' -f $zipCmsWebsiteTarget)
    Write-Output ('')

    Invoke-Unzip -Source $zipCmsWebsiteSource -Target $zipCmsWebsiteTarget

    Write-Output ('')
    Write-Output ('Zip Extracted CMS Website')
    Write-Output ('')
}

Invoke-Main
