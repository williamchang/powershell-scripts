<#

Microsoft PowerShell

Install Sitecore Configure MS-SQL
Created by William Chang

Created: 2016-12-06
Modified: 2016-12-06

#>

$currentScriptName = 'Install_Sitecore_ConfigureMSSQL'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

$cmsWebrootFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com'
$cmsDatabaseFolderPath = Join-Path -Path $currentFolderPath -ChildPath 'site1.com.databases'
$cmsDatabaseConfigChildPath = Join-Path -Path 'App_Config' -ChildPath 'ConnectionStrings.config'

$executableSqlcmdPath = 'sqlcmd.exe'

function Add-MicrosoftSqlDatabase {
    param(
        [string]$SqlCmdPath,
        [string]$DatabaseName,
        [string]$DataPath,
        [string]$LogPath
    )

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
    Write-Output ('')

    Write-Output ('')
    Write-Output ('Debug Preference : {0}' -f $DebugPreference)
    Write-Output ('')

    Write-Output ('')
    Write-Output ('CMS Database Folder Path : {0}' -f $cmsDatabaseFolderPath)
    Write-Output ('')

    Write-Output ('==========')

    $sqlDatabaseCoreName = 'Sitecore_Core'
    $sqlDatabaseDataPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Core.mdf'
    $sqlDatabaseLogPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Core.ldf'

    Write-Output ('')
    Write-Output ('Data Path of CMS Database : {0}' -f $sqlDatabaseDataPath)
    Write-Output ('Log Path of CMS Database: {0}' -f $sqlDatabaseLogPath)
    Write-Output ('')

    Add-MicrosoftSqlDatabase -SqlCmdPath $executableSqlcmdPath -DatabaseName $sqlDatabaseCoreName -DataPath $sqlDatabaseDataPath -LogPath $sqlDatabaseLogPath

    Write-Output ('==========')

    $sqlDatabaseMasterName = 'Sitecore_Master'
    $sqlDatabaseDataPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Master.mdf'
    $sqlDatabaseLogPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Master.ldf'

    Write-Output ('')
    Write-Output ('Data Path of CMS Database : {0}' -f $sqlDatabaseDataPath)
    Write-Output ('Log Path of CMS Database: {0}' -f $sqlDatabaseLogPath)
    Write-Output ('')

    Add-MicrosoftSqlDatabase -SqlCmdPath $executableSqlcmdPath -DatabaseName $sqlDatabaseMasterName -DataPath $sqlDatabaseDataPath -LogPath $sqlDatabaseLogPath

    Write-Output ('==========')

    $sqlDatabaseWebName = 'Sitecore_Web'
    $sqlDatabaseDataPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Web.mdf'
    $sqlDatabaseLogPath = Join-Path -Path $cmsDatabaseFolderPath -ChildPath 'Sitecore.Web.ldf'

    Write-Output ('')
    Write-Output ('Data Path of CMS Database : {0}' -f $sqlDatabaseDataPath)
    Write-Output ('Log Path of CMS Database: {0}' -f $sqlDatabaseLogPath)
    Write-Output ('')

    Add-MicrosoftSqlDatabase -SqlCmdPath $executableSqlcmdPath -DatabaseName $sqlDatabaseWebName -DataPath $sqlDatabaseDataPath -LogPath $sqlDatabaseLogPath

    Write-Output ('==========')

    Set-DatabaseSetting -ConfigPath (Join-Path -Path $cmsWebrootFolderPath -ChildPath $cmsDatabaseConfigChildPath) -DatabaseCoreName $sqlDatabaseCoreName -DatabaseMasterName $sqlDatabaseMasterName -DatabaseWebName $sqlDatabaseWebName
}

Invoke-Main
