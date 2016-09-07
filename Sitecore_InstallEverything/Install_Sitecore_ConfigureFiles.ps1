<#

Microsoft PowerShell

Install Sitecore Configure Files
Created by William Chang

Created: 2016-09-03
Modified: 2016-09-06

#>

$currentScriptName = 'Install_Sitecore_ConfigureFiles'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

$cmsWebrootFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com'
$cmsDataFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com.data'
$cmsDatabaseFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com.databases'

$cmsWebConfigChildPath = 'Web.config'
$cmsSitecoreConfigChildPath = Join-Path -Path 'App_Config' -ChildPath 'Sitecore.config'
$cmsDatabaseConfigChildPath = Join-Path -Path 'App_Config' -ChildPath 'ConnectionStrings.config'

function Set-CommentXmlNode {
    param(
        [System.Xml.XmlElement]$Node
    )
    if($Node -ne $Null) {
        $xmlComment = $xmlDocument.CreateComment($Node.OuterXml)
        $Node.ParentNode.ReplaceChild($xmlComment, $Node) | Out-Null
    }
}

function Set-WebDebugSetting {
    param(
        [string]$ConfigPath
    )
    if(Test-Path -Path $ConfigPath) {
        $xmlDocument = (Get-Content $ConfigPath) -as [xml]
        $xmlNode = $xmlDocument.'configuration'.'system.web'.'compilation'
        $xmlNode.'debug' = 'true'
        $xmlDocument.Save($ConfigPath)
    } else {
        Write-Error 'Error in Set-WebDebugSetting function.'
    }
}

function Set-DatabaseSetting {
    param(
        [string]$ConfigPath,
        [string]$DatabaseFolderPath
    )
    if((Test-Path -Path $ConfigPath) -and (Test-Path -Path $DatabaseFolderPath)) {
        $xmlDocument = (Get-Content $ConfigPath) -as [xml]

        #[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
        #$sqlServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList localhost

        #$sqlService = Get-Service -DisplayName 'SQL Server (*' | Where-Object {$_.'Status' -eq 'Running'}
        #$sqlInstanceName = $sqlService.DisplayName.Split('(')[1].Trim(')')

        $sqlInstanceName = '(local)'
        $sqlAttachDatabasePath = Join-Path -Path $DatabaseFolderPath -ChildPath 'Sitecore.Core.mdf'
        $xmlNode = $xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'core'}
        $xmlNode.'connectionString' = 'User Instance=True;Trusted_Connection=True;Server={0};AttachDBFilename={1}' -f $sqlInstanceName, $sqlAttachDatabasePath

        $sqlInstanceName = '(local)'
        $sqlAttachDatabasePath = Join-Path -Path $DatabaseFolderPath -ChildPath 'Sitecore.Master.mdf'
        $xmlNode = $xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'master'}
        $xmlNode.'connectionString' = 'User Instance=True;Trusted_Connection=True;Server={0};AttachDBFilename={1}' -f $sqlInstanceName, $sqlAttachDatabasePath

        $sqlInstanceName = '(local)'
        $sqlAttachDatabasePath = Join-Path -Path $DatabaseFolderPath -ChildPath 'Sitecore.Web.mdf'
        $xmlNode = $xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'web'}
        $xmlNode.'connectionString' = 'User Instance=True;Trusted_Connection=True;Server={0};AttachDBFilename={1}' -f $sqlInstanceName, $sqlAttachDatabasePath

        Set-CommentXmlNode -Node ($xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'analytics'})
        Set-CommentXmlNode -Node ($xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'tracking.live'})
        Set-CommentXmlNode -Node ($xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'tracking.history'})
        Set-CommentXmlNode -Node ($xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'tracking.contact'})
        Set-CommentXmlNode -Node ($xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'reporting'})

        $xmlDocument.Save($ConfigPath)
    } else {
        Write-Error 'Error in Set-DatabaseSetting function.'
    }
}

function Set-SitecoreDataSetting {
    param(
        [string]$ConfigPath,
        [string]$DataFolderPath
    )
    if((Test-Path -Path $ConfigPath) -and (Test-Path -Path $DataFolderPath)) {
        $xmlDocument = (Get-Content $ConfigPath) -as [xml]
        $xmlNode = $xmlDocument.'sitecore'.'sc.variable' | Where-Object {$_.'name' -eq 'dataFolder'}
        $xmlNode.'value' = $DataFolderPath
        $xmlDocument.Save($ConfigPath)
    } else {
        Write-Error 'Error in Set-SitecoreDataSetting function.'
    }
}

function Set-SitecoreCmsOnlyMode {
    param(
        [string]$WebrootFolderPath
    )
    if(Test-Path -Path $WebrootFolderPath) {
        # Modify App_Config\Include\Sitecore.Commerce.config
        $xmlConfigPath = Join-Path $WebrootFolderPath -ChildPath 'App_Config' | Join-Path -ChildPath 'Include' | Join-Path -ChildPath 'Sitecore.Commerce.config'
        if(Test-Path -Path $xmlConfigPath) {
            $xmlDocument = (Get-Content $xmlConfigPath) -as [xml]
            Set-CommentXmlNode -Node ($xmlDocument.'configuration'.'sitecore'.'pipelines'.'getContentEditorWarnings'.'processor' | Where-Object {$_.'type' -like '*ContentEditorLicenseWarning*'})
            $xmlDocument.Save($xmlConfigPath)
        }

        # Modify App_Config\Include\Sitecore.Xdb.config
        $xmlConfigPath = Join-Path $WebrootFolderPath -ChildPath 'App_Config' | Join-Path -ChildPath 'Include' | Join-Path -ChildPath 'Sitecore.Xdb.config'
        if(Test-Path -Path $xmlConfigPath) {
            $xmlDocument = (Get-Content $xmlConfigPath) -as [xml]
            $xmlNode = $xmlDocument.'configuration'.'sitecore'.'settings'.'setting' | Where-Object {$_.'name' -eq 'Xdb.Enabled'}
            if($xmlNode -ne $Null) {
                $xmlNode.'value' = 'false'
            }
            $xmlNode = $xmlDocument.'configuration'.'sitecore'.'settings'.'setting' | Where-Object {$_.'name' -eq 'Xdb.Tracking.Enabled'}
            if($xmlNode -ne $Null) {
                $xmlNode.'value' = 'false'
            }
            $xmlDocument.Save($xmlConfigPath)
        }

        # Modify App_Config\Include\Sitecore.Analytics.config
        $xmlConfigPath = Join-Path $WebrootFolderPath -ChildPath 'App_Config' | Join-Path -ChildPath 'Include' | Join-Path -ChildPath 'Sitecore.Analytics.config'
        if(Test-Path -Path $xmlConfigPath) {
            $xmlDocument = (Get-Content $xmlConfigPath) -as [xml]
            $xmlNode = $xmlDocument.'configuration'.'sitecore'.'settings'.'setting' | Where-Object {$_.'name' -eq 'Analytics.Enabled'}
            if($xmlNode -ne $Null) {
                $xmlNode.'value' = 'false'
            }
            $xmlDocument.Save($xmlConfigPath)
        }
    } else {
        Write-Error 'Error in Set-SitecoreCmsOnlyMode function.'
    }
}

function Invoke-Main {
    Write-Output ('')
    Write-Output ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
    Write-Output ('Current Date And Time : {0}' -f $currentDateTime)
    Write-Output ('Current Folder Path : {0}' -f $currentFolderPath)
    Write-Output ('')

    Write-Output ('')
    Write-Output ('CMS Webroot Folder Path : {0}' -f $cmsWebrootFolderPath)
    Write-Output ('CMS Database Folder Path : {0}' -f $cmsDatabaseFolderPath)
    Write-Output ('')

    #Set-WebDebugSetting -ConfigPath (Join-Path -Path $cmsWebrootFolderPath -ChildPath $cmsWebConfigChildPath)
    Set-DatabaseSetting -ConfigPath (Join-Path -Path $cmsWebrootFolderPath -ChildPath $cmsDatabaseConfigChildPath) -DatabaseFolderPath $cmsDatabaseFolderPath
    Set-SitecoreDataSetting -ConfigPath (Join-Path -Path $cmsWebrootFolderPath -ChildPath $cmsSitecoreConfigChildPath) -DataFolderPath $cmsDataFolderPath
    Set-SitecoreCmsOnlyMode -WebrootFolderPath $cmsWebrootFolderPath
}

Invoke-Main
