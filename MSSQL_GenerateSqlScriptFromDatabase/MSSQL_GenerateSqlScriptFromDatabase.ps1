<#

Microsoft PowerShell

Generate SQL Script From Microsoft SQL Server Database
Created by William Chang

Created: 2014-08-27
Modified: 2015-01-09

SQLCMD Examples:
sqlcmd.exe -x -i C:\path\to\file.sql
sqlcmd.exe -a 32767 -x -i C:\path\to\file.sql

PowerShell Examples:
powershell.exe Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
powershell.exe -File .\PowerShell_Sandbox.ps1
powershell.exe -File C:\Temp\PowerShell_Sandbox.ps1

References:
https://www.simple-talk.com/sql/database-administration/automated-script-generation-with-powershell-and-smo/
http://sev17.com/2011/07/24/using-smo-transfer-class-to-script-database-objects/
http://samritchie.net/2011/03/31/vsdbcmd-deployment-to-sql-azure/
http://technet.microsoft.com/en-us/library/ms186472(v=sql.105).aspx
http://msdn.microsoft.com/en-us/library/Microsoft.SqlServer.Management.Smo.ScriptingOptions_properties.aspx
http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.transferbase_properties.aspx

#>

Clear-Host

$currentScriptName = "MSSQL_GenerateSqlScriptFromDatabase"
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

#Stop-Transcript | Out-Null
$logFileName = '{0}.{1}.log' -f $currentScriptName, $currentDateTime
$logFilePath = '{0}\{1}' -f $currentFolderPath, $logFileName
Start-Transcript -Path $logFilePath -Append

$executableSqlcmdPath = 'sqlcmd.exe'
$sqlServerName = ''
$sqlDatabaseName = ''
$sqlScriptDatabaseName = ''
$sqlScriptFilePath = ''
$sqlBatchFilePath = ''

Write-Host ("`n")
Write-Host ("Current Date And Time : {0}" -f $currentDateTime)
Write-Host ("Current Folder Path : {0}" -f $currentFolderPath)
Write-Host ("Executable SQLCMD Path : {0}" -f $executableSqlcmdPath)
Write-Host ("`n")

try
{
    Invoke-Expression -Command ("{0} -E -Q ""SET NOCOUNT ON;SELECT @@VERSION;"" -h-1" -f $executableSqlcmdPath)
}
catch [System.Management.Automation.CommandNotFoundException]
{
    Write-Host ("`n`nSQLCMD executable not found.`n`n")
    exit
}

$sqlServerName = Read-Host "What is the database server name or address?"
Write-Host ("`n`n")
if(!$sqlServerName -or $sqlServerName.length -lt 3)
{
    Write-Host ("`n`nInvalid input of server name or address.`n`n")
    exit
}

$sqlDatabaseName = Read-Host "What is the database name?"
Write-Host ("`n`n")
if(!$sqlDatabaseName -or $sqlDatabaseName.length -lt 3)
{
    Write-Host ("`n`nInvalid input of database name.`n`n")
    exit
}

$sqlScriptDatabaseName = Read-Host "What database name for the SQL script?"
Write-Host ("`n`n")
if(!$sqlScriptDatabaseName -or $sqlScriptDatabaseName.length -lt 3)
{
    $sqlScriptDatabaseName = $sqlDatabaseName
}

$sqlScriptFilePath = '{0}\{1}.{2}.sql' -f $currentFolderPath, $sqlScriptDatabaseName, $currentDateTime
$sqlBatchFilePath = '{0}\{1}.{2}.bat' -f $currentFolderPath, $sqlScriptDatabaseName, $currentDateTime

Write-Host ("`n`n")
Write-Host ("SQL Server Name : {0}" -f $sqlServerName)
Write-Host ("SQL Database Name : {0}" -f $sqlDatabaseName)
Write-Host ("SQL Script Database Name : {0}" -f $sqlScriptDatabaseName)
Write-Host ("SQL Script File Path : {0}" -f $sqlScriptFilePath)
Write-Host ("SQL Batch File Path : {0}" -f $sqlBatchFilePath)
Write-Host ("`n`n")

$sqlTestDatabaseCommand = "{0} -S {1} -E -Q ""sp_dbcmptlevel {2}"" -h-1 -W" -f $executableSqlcmdPath, $sqlServerName, $sqlDatabaseName
$sqlTestDatabaseCommandOutput = Invoke-Expression -Command $sqlTestDatabaseCommand | Out-String
Write-Host ("`n`n")
if($sqlTestDatabaseCommandOutput -like "*not open a connection*")
{
    Write-Host ("`n`nThe database server is not found or not accessible.`n`n")
    exit
}
elseif($sqlTestDatabaseCommandOutput -like "*valid database name*")
{
    Write-Host ("`n`nThe database does not exist.`n`n")
    exit
}

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | Out-Null

$mssqlServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $sqlServerName
if($mssqlServer.Version -eq  $null) {Throw 'The database server is not found or not accessible.'}
$db = $mssqlServer.databases[$sqlDatabaseName]
if($db.name -ne $sqlDatabaseName) {Throw 'The database does not exist.'}

$mssqlScriptingOptions = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ScriptingOptions'
$mssqlScriptingOptions.AnsiPadding = $true # default true
$mssqlScriptingOptions.AppendToFile = $true # default false
$mssqlScriptingOptions.ClusteredIndexes = $true # default false
$mssqlScriptingOptions.ExtendedProperties = $true # default true
$mssqlScriptingOptions.Default = $true # default true
$mssqlScriptingOptions.DriAll = $true # default false
$mssqlScriptingOptions.IncludeHeaders = $false # default true
$mssqlScriptingOptions.IncludeIfNotExists = $true # default false
$mssqlScriptingOptions.Indexes = $true # default false
$mssqlScriptingOptions.NoCommandTerminator = $false # default false
$mssqlScriptingOptions.SchemaQualify = $true # default true
$mssqlScriptingOptions.ToFileOnly = $true # default false
$mssqlScriptingOptions.Triggers = $true # default false
$mssqlScriptingOptions.WithDependencies = $true # default true

$mssqlScriptingOptions.TargetDatabaseEngineType = "Standalone"
$mssqlScriptingOptions.TargetServerVersion = "Version100"
$mssqlScriptingOptions.FileName = $sqlScriptFilePath

$mssqlTransfer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Transfer' -ArgumentList $db
$mssqlTransfer.CopyAllObjects = $true # default false
$mssqlTransfer.CreateTargetDatabase = $true # default false
$mssqlTransfer.Options = $mssqlScriptingOptions

$mssqlScripter = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Scripter' -ArgumentList $mssqlServer
$mssqlScripter.Options = $mssqlScriptingOptions

# Generate Create Database Script
@"
/* Script Date : {1} */
CREATE DATABASE [{0}]
GO
ALTER DATABASE [{0}] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
BEGIN
EXEC [{0}].[dbo].[sp_fulltext_database] @action = 'enable'
END
GO
"@ -f $sqlScriptDatabaseName, $currentDateTime | Out-File -Append -FilePath $sqlScriptFilePath

# Generate Use Database Script
'USE [{0}]' -f $sqlScriptDatabaseName | Out-File -Append -FilePath $sqlScriptFilePath
'GO' | Out-File -Append -FilePath $sqlScriptFilePath

# Generate Drop Schema Objects Script
$mssqlTransfer.Options.ScriptData = $false
$mssqlTransfer.Options.ScriptSchema = $true
$mssqlTransfer.Options.ScriptDrops = $true
$mssqlTransfer.ScriptTransfer()

# Generate Create Schema Objects Script
$mssqlTransfer.Options.ScriptData = $false
$mssqlTransfer.Options.ScriptSchema = $true
$mssqlTransfer.Options.ScriptDrops = $false
$mssqlTransfer.ScriptTransfer()

# Generate Insert Data Script
$mssqlScripter.Options.ScriptData = $true
$mssqlScripter.Options.ScriptSchema = $false
$mssqlScripter.EnumScript([Microsoft.SqlServer.Management.Smo.SqlSmoObject[]]$db.Tables)

function SearchAndReplace($filePath)
{
    (Get-Content $filePath) | Foreach-Object {$_ -replace "\$", "' + CHAR(36) + '"} | Set-Content $filePath
}

# Search And Replace SQL Variable Substitution
#SearchAndReplace($sqlScriptFilePath)

# Create Microsoft Windows Batch File To Run Database Script
@"
@echo off
setlocal enabledelayedexpansion

:: Run SQL Script Using Microsoft SQLCMD

echo.
echo BEGIN Script
echo.

:: Run operation.
echo.
echo BEGIN Operation
echo.

sqlcmd.exe -x -s local -i {0}.{1}.sql

echo.
echo END Operation
echo.

:end
echo.
echo END Script
echo.

:: Keep command window open.
pause
"@ -f $sqlScriptDatabaseName, $currentDateTime | Out-File -FilePath $sqlBatchFilePath

Stop-Transcript
