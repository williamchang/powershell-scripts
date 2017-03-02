<#

Microsoft PowerShell

Install Sitecore Unzip Release Archive File
Created by William Chang

Created: 2016-09-03
Modified: 2017-03-02

#>

param(
    [string]$CmsZipFileBaseName = $(throw '-CmsZipFileBaseName is required (do not include the file extension).')
)

$currentScriptName = 'Install_Sitecore_UnzipReleaseArchiveFile'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

$zipFileBaseName = $CmsZipFileBaseName # eg 'Sitecore 8.2 rev. 161221'
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

function Add-Folder {
    param(
        [string]$Target
    )
    if(!(Test-Path -Path $Target)) {
        New-Item -Path $Target -ItemType Directory | Out-Null
    }
}

function Invoke-Main {
    Write-Debug ('')
    Write-Debug ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
    Write-Debug ('PowerShell Debug Preference : {0}' -f $DebugPreference)
    Write-Debug ('Current Date And Time : {0}' -f $currentDateTime)
    Write-Debug ('Current Folder Path : {0}' -f $currentFolderPath)
    Write-Debug ('')

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
    Write-Output ('Zip Extracted for CMS Data')
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
    Write-Output ('Zip Extracted for CMS Databases')
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
    Write-Output ('Zip Extracted for CMS Website')
    Write-Output ('')

    Write-Output ('==========')

    $zipCmsMediaLibraryTarget = Join-Path -Path $currentFolderPath -ChildPath 'site1.com.medialibrary'
    $zipCmsMediaLibraryCacheTarget = Join-Path -Path $zipCmsMediaLibraryTarget -ChildPath 'MediaCache'
    $zipCmsMediaLibraryFilesTarget = Join-Path -Path $zipCmsMediaLibraryTarget -ChildPath 'MediaFiles'

    Write-Output ('')
    Write-Output ('Folder Target of CMS Media Library : {0}' -f $zipCmsMediaLibraryTarget)
    Write-Output ('Folder Target of CMS Media Library Cache : {0}' -f $zipCmsMediaLibraryCacheTarget)
    Write-Output ('Folder Target of CMS Media Library Files : {0}' -f $zipCmsMediaLibraryFilesTarget)
    Write-Output ('')

    Add-Folder -Target $zipCmsMediaLibraryTarget
    Add-Folder -Target $zipCmsMediaLibraryCacheTarget
    Add-Folder -Target $zipCmsMediaLibraryFilesTarget

    Write-Output ('')
    Write-Output ('Folders Created for CMS Media Library')
    Write-Output ('')

    Write-Output ('==========')

    Write-Output ('')
    Write-Output ('Files unzipped for CMS')
    Write-Output ('')
}

Invoke-Main
