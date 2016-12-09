<#

Microsoft PowerShell

Install Sitecore Configure MS-SQL
Created by William Chang

Created: 2016-12-06
Modified: 2016-12-09

#>

$currentScriptName = 'Install_Sitecore_ConfigureMSSQL'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

$cmsWebrootFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com'
$cmsDatabaseFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com.databases'
$cmsDatabaseConfigChildPath = Join-Path -Path 'App_Config' -ChildPath 'ConnectionStrings.config'
$cmsDatabasePrefixName = 'Sandbox'

function Add-MicrosoftSqlDatabase {
    param(
        [string]$SqlCmdPath,
        [string]$DatabaseName,
        [string]$DataPath,
        [string]$LogPath
    )
    if(!$SqlCmdPath) {
        $SqlCmdPath = 'sqlcmd.exe'
    }
    $sqlQuery = 'IF NOT EXISTS (SELECT name FROM master.sys.databases WHERE name = ''{0}'') CREATE DATABASE {0} ON (NAME = ''{0}_Data'', FILENAME = ''{1}'') LOG ON (NAME = ''{0}_Log'', FILENAME = ''{2}'') FOR ATTACH WITH ENABLE_BROKER;' -f $DatabaseName, $DataPath, $LogPath
    $sqlCommand = '{0} -E -Q "{1}"' -f $SqlCmdPath, $sqlQuery
    Invoke-Expression -Command $sqlCommand
}

function Set-CommentXmlNode {
    param(
        [System.Xml.XmlElement]$Node
    )
    if($Node -ne $Null) {
        $xmlComment = $xmlDocument.CreateComment($Node.OuterXml)
        $Node.ParentNode.ReplaceChild($xmlComment, $Node) | Out-Null
    }
}

function Set-DatabaseSetting {
    param(
        [string]$ConfigPath,
        [string]$DatabaseCoreName,
        [string]$DatabaseMasterName,
        [string]$DatabaseWebName
    )
    if(Test-Path -Path $ConfigPath) {
        $xmlDocument = (Get-Content $ConfigPath) -as [xml]

        $sqlServerAddress = '(local)'
        $xmlNode = $xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'core'}
        $xmlNode.'connectionString' = 'user id=sa;password=sa;data source={0};database={1}' -f $sqlServerAddress, $DatabaseCoreName

        $sqlServerAddress = '(local)'
        $xmlNode = $xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'master'}
        $xmlNode.'connectionString' = 'user id=sa;password=sa;data source={0};database={1}' -f $sqlServerAddress, $DatabaseMasterName

        $sqlServerAddress = '(local)'
        $xmlNode = $xmlDocument.'connectionStrings'.'add' | Where-Object {$_.'name' -eq 'web'}
        $xmlNode.'connectionString' = 'user id=sa;password=sa;data source={0};database={1}' -f $sqlServerAddress, $DatabaseWebName

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

function Invoke-Main {
    Write-Output ('')
    Write-Output ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
    Write-Output ('Current Date And Time : {0}' -f $currentDateTime)
    Write-Output ('Current Folder Path : {0}' -f $currentFolderPath)
    Write-Output ('Debug Preference : {0}' -f $DebugPreference)
    Write-Output ('')

    Write-Output ('')
    Write-Output ('CMS Webroot Folder Path : {0}' -f $cmsWebrootFolderPath)
    Write-Output ('CMS Database Folder Path : {0}' -f $cmsDatabaseFolderPath)
    Write-Output ('')

    Write-Output ('==========')

    $sqlDatabaseCoreName = '{0}_Sitecore_Core' -f $cmsDatabasePrefixName
    $sqlDatabaseDataPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Core.mdf'
    $sqlDatabaseLogPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Core.ldf'

    Write-Output ('')
    Write-Output ('Database Name of CMS Database : {0}' -f $sqlDatabaseCoreName)
    Write-Output ('Data Path of CMS Database : {0}' -f $sqlDatabaseDataPath)
    Write-Output ('Log Path of CMS Database: {0}' -f $sqlDatabaseLogPath)
    Write-Output ('')

    Add-MicrosoftSqlDatabase -DatabaseName $sqlDatabaseCoreName -DataPath $sqlDatabaseDataPath -LogPath $sqlDatabaseLogPath

    Write-Output ('==========')

    $sqlDatabaseMasterName = '{0}_Sitecore_Master' -f $cmsDatabasePrefixName
    $sqlDatabaseDataPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Master.mdf'
    $sqlDatabaseLogPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Master.ldf'

    Write-Output ('')
    Write-Output ('Database Name of CMS Database : {0}' -f $sqlDatabaseMasterName)
    Write-Output ('Data Path of CMS Database : {0}' -f $sqlDatabaseDataPath)
    Write-Output ('Log Path of CMS Database: {0}' -f $sqlDatabaseLogPath)
    Write-Output ('')

    Add-MicrosoftSqlDatabase -DatabaseName $sqlDatabaseMasterName -DataPath $sqlDatabaseDataPath -LogPath $sqlDatabaseLogPath

    Write-Output ('==========')

    $sqlDatabaseWebName = '{0}_Sitecore_Web' -f $cmsDatabasePrefixName
    $sqlDatabaseDataPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Web.mdf'
    $sqlDatabaseLogPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Web.ldf'

    Write-Output ('')
    Write-Output ('Database Name of CMS Database : {0}' -f $sqlDatabaseWebName)
    Write-Output ('Data Path of CMS Database : {0}' -f $sqlDatabaseDataPath)
    Write-Output ('Log Path of CMS Database: {0}' -f $sqlDatabaseLogPath)
    Write-Output ('')

    Add-MicrosoftSqlDatabase -DatabaseName $sqlDatabaseWebName -DataPath $sqlDatabaseDataPath -LogPath $sqlDatabaseLogPath

    Write-Output ('==========')

    Write-Output ('')
    Write-Output ('Database Core Name of CMS Database : {0}' -f $sqlDatabaseCoreName)
    Write-Output ('Database Master Name of CMS Database : {0}' -f $sqlDatabaseMasterName)
    Write-Output ('Database Web Name of CMS Database : {0}' -f $sqlDatabaseWebName)
    Write-Output ('')

    Set-DatabaseSetting -ConfigPath (Join-Path -Path $cmsWebrootFolderPath -ChildPath $cmsDatabaseConfigChildPath) -DatabaseCoreName $sqlDatabaseCoreName -DatabaseMasterName $sqlDatabaseMasterName -DatabaseWebName $sqlDatabaseWebName
}

Invoke-Main
