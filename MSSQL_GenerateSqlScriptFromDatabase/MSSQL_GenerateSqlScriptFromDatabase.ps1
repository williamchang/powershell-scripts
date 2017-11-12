<#

Microsoft PowerShell

Generate SQL Script From Microsoft SQL Server Database
Created by William Chang

Created: 2014-08-27
Modified: 2017-11-10

SQLCMD Examples:
sqlcmd.exe -x -i C:\path\to\file.sql
sqlcmd.exe -a 32767 -x -i C:\path\to\file.sql

PowerShell Examples:
powershell.exe Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
powershell.exe -File .\MSSQL_GenerateSqlScriptFromDatabase.ps1
powershell.exe -File C:\Temp\MSSQL_GenerateSqlScriptFromDatabase.ps1

References:
https://www.simple-talk.com/sql/database-administration/automated-script-generation-with-powershell-and-smo/
http://sev17.com/2011/07/24/using-smo-transfer-class-to-script-database-objects/
http://samritchie.net/2011/03/31/vsdbcmd-deployment-to-sql-azure/
http://technet.microsoft.com/en-us/library/ms186472(v=sql.105).aspx
http://msdn.microsoft.com/en-us/library/Microsoft.SqlServer.Management.Smo.ScriptingOptions_properties.aspx
http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.transferbase_properties.aspx

Microsoft SQL Server - Generate and Publish Scripts - Advanced Scripting Options
ANSI Padding : True
Script for Server Version : SQL Server 2012
Types of data to script : Schema and data
Script Triggers : True

#>

param(
    [string]$SqlServerName = $null,
    [string]$SqlDatabaseName = $null,
    [string]$SqlScriptDatabaseName = $null,
    [switch]$SqlVariableSubstitution = $false
)

Clear-Host

$currentScriptName = 'MSSQL_GenerateSqlScriptFromDatabase'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

#Stop-Transcript | Out-Null
$logFileName = '{0}.{1}.log.txt' -f $currentScriptName, $currentDateTime
$logFilePath = '{0}\{1}' -f $currentFolderPath, $logFileName
Start-Transcript -Path $logFilePath -Append

$executableSqlcmdFilePath = 'sqlcmd.exe'

Write-Output ('')
Write-Output ('PowerShell Installation Path : {0}' -f $PsHome)
Write-Output ('PowerShell Version : {0}' -f $PsVersionTable.PSVersion)
Write-Output ('PowerShell Common Language Runtime Version : {0}' -f $PsVersionTable.CLRVersion)
Write-Output ('PowerShell Debug Preference : {0}' -f $DebugPreference)
Write-Output ('Executable SQLCMD File Path : {0}' -f $executableSqlcmdFilePath)
Write-Output ('')

try
{
    Write-Output ('')
    Write-Output ('')

    <# Use PowerShell array operator. #>
    $executableCommandParameters = @('-E', '-Q', "SET NOCOUNT ON;SELECT @@VERSION;", '-h-1')

    <# Use PowerShell call operator aka invocation operator. #>
    & $executableSqlcmdFilePath $executableCommandParameters
}
catch [System.Management.Automation.CommandNotFoundException]
{
    Write-Output ('SQLCMD executable not found.')
    Write-Output ('')
    Exit
}

if(!$SqlServerName -and !$SqlDatabaseName -and !$SqlScriptDatabaseName)
{
    Write-Output ('')
    Write-Output ('')

    $SqlServerName = Read-Host -Prompt 'What is the database server name or address?'
    Write-Host ('')
    Write-Host ('')
    if(!$SqlServerName -or $SqlServerName.length -lt 3)
    {
        Write-Host ('')
        Write-Host ('Invalid input of server name or address.') -ForegroundColor Red
        Write-Host ('')
        Exit
    }

    $SqlDatabaseName = Read-Host -Prompt 'What is the database name in the database server?'
    Write-Host ('')
    Write-Host ('')
    if(!$SqlDatabaseName -or $SqlDatabaseName.length -lt 3)
    {
        Write-Host ('')
        Write-Host ('Invalid input of database name.') -ForegroundColor Red
        Write-Host ('')
        Exit
    }

    $SqlScriptDatabaseName = Read-Host -Prompt 'What database name to put into the SQL script?'
    Write-Host ('')
    Write-Host ('')
    if(!$SqlScriptDatabaseName -or $SqlScriptDatabaseName.length -lt 3)
    {
        $SqlScriptDatabaseName = $SqlDatabaseName
    }
}

if(!$SqlServerName) {Throw '-SqlServerName is required.'}
if(!$SqlDatabaseName) {Throw '-SqlDatabaseName is required.'}
if(!$SqlScriptDatabaseName) {$SqlScriptDatabaseName = $SqlDatabaseName}

$sqlScriptFilePath = '{0}\{1}.{2}.sql' -f $currentFolderPath, $SqlScriptDatabaseName, $currentDateTime
$sqlBatchFilePath = '{0}\{1}.{2}.bat' -f $currentFolderPath, $SqlScriptDatabaseName, $currentDateTime

Write-Output ('')
Write-Output ('SQL Server Name : {0}' -f $SqlServerName)
Write-Output ('SQL Database Name : {0}' -f $SqlDatabaseName)
Write-Output ('SQL Script Database Name : {0}' -f $SqlScriptDatabaseName)
Write-Output ('SQL Script File Path : {0}' -f $sqlScriptFilePath)
Write-Output ('SQL Batch File Path : {0}' -f $sqlBatchFilePath)
Write-Output ('')

Write-Output ('')
Write-Output ('')
$executableCommandParameters = @('-S', $SqlServerName, '-E', '-Q', ("sp_dbcmptlevel {0}" -f $SqlDatabaseName), '-h-1', '-W')
$sqlTestDatabaseCommandOutput = & $executableSqlcmdFilePath $executableCommandParameters 2>&1
if($sqlTestDatabaseCommandOutput -like '*not open a connection*')
{
    Write-Output ('The database server is not found or not accessible.')
    Write-Output ('')
    Exit
}
elseif($sqlTestDatabaseCommandOutput -like '*valid database name*')
{
    Write-Output ('The database does not exist.')
    Write-Output ('')
    Exit
}
Write-Output ('')
Write-Output ('')

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | Out-Null

$mssqlServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $SqlServerName
if($mssqlServer.Version -eq  $null) {Throw 'The database server is not found or not accessible.'}

$mssqlDatabase = $mssqlServer.Databases[$SqlDatabaseName]
if($mssqlDatabase.Name -ne $SqlDatabaseName) {Throw 'The database does not exist.'}

<#
$mssqlDatabaseObjects = $mssqlDatabase.Tables
$mssqlDatabaseObjects += $mssqlDatabase.Views
$mssqlDatabaseObjects += $mssqlDatabase.StoredProcedures
$mssqlDatabaseObjects += $mssqlDatabase.UserDefinedFunctions
#>

$mssqlScriptingOptions = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ScriptingOptions'
$mssqlScriptingOptions.AnsiPadding = $true # default true
$mssqlScriptingOptions.AppendToFile = $true # default false
$mssqlScriptingOptions.ClusteredIndexes = $true # default false
$mssqlScriptingOptions.Encoding = [System.Text.Encoding]::UTF8
$mssqlScriptingOptions.ExtendedProperties = $true # default false
$mssqlScriptingOptions.FileName = $sqlScriptFilePath
$mssqlScriptingOptions.Default = $true # default false
$mssqlScriptingOptions.DriAll = $true # default false
$mssqlScriptingOptions.IncludeDatabaseRoleMemberships = $true # default false
$mssqlScriptingOptions.IncludeHeaders = $true # default false
$mssqlScriptingOptions.IncludeIfNotExists = $false # default false
$mssqlScriptingOptions.Indexes = $true # default false
$mssqlScriptingOptions.NoCollation = $true # default false
$mssqlScriptingOptions.NoCommandTerminator = $false # default false
$mssqlScriptingOptions.SchemaQualify = $true # default true
$mssqlScriptingOptions.ScriptBatchTerminator = $false # default false
$mssqlScriptingOptions.Statistics = $false # default false
$mssqlScriptingOptions.TargetDatabaseEngineType = [Microsoft.SqlServer.Management.Common.DatabaseEngineType]::Standalone
$mssqlScriptingOptions.TargetServerVersion = [Microsoft.SqlServer.Management.Smo.SqlServerVersion]::Version110
$mssqlScriptingOptions.ToFileOnly = $true # default false
$mssqlScriptingOptions.Triggers = $true # default false
$mssqlScriptingOptions.WithDependencies = $true # default true
$mssqlScriptingOptions.XmlIndexes = $true # default false

$mssqlTransfer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Transfer' -ArgumentList $mssqlDatabase
$mssqlTransfer.CopyAllObjects = $true # default false
$mssqlTransfer.Options = $mssqlScriptingOptions

# Generate Create Database Script
@"
/* Script Date: {1} */
/****** Object:  Database [{0}] ******/
CREATE DATABASE [{0}]
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
BEGIN
EXEC [{0}].[dbo].[sp_fulltext_database] @action = 'enable'
END
GO
ALTER DATABASE [{0}] SET COMPATIBILITY_LEVEL = 110
GO
"@ -f $SqlScriptDatabaseName, $currentDateTime | Out-File -Encoding 'UTF8' -Append -FilePath $sqlScriptFilePath

# Generate Use Database Script
'USE [{0}]' -f $SqlScriptDatabaseName | Out-File -Encoding 'UTF8' -Append -FilePath $sqlScriptFilePath
'GO' | Out-File -Encoding 'UTF8' -Append -FilePath $sqlScriptFilePath

# Generate Schema And Data Script
$mssqlTransfer.Options.ScriptOwner = $false # default false
$mssqlTransfer.Options.ScriptData = $true
$mssqlTransfer.Options.ScriptSchema = $true
$mssqlTransfer.Options.ScriptDrops = $false # default false
$mssqlTransfer.EnumScriptTransfer()

function SearchAndReplace($filePath)
{
    (Get-Content $filePath) | Foreach-Object {$_ -replace "\$", "' + CHAR(36) + '"} | Set-Content $filePath
}

# Search And Replace SQL Variable Substitution
if($SqlVariableSubstitution)
{
    SearchAndReplace($sqlScriptFilePath)
}

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

sqlcmd.exe -S 127.0.0.1 -a 32767 -x -i {0}.{1}.sql -o {0}.{1}.log.txt

echo.
echo END Operation
echo.

:end
echo.
echo END Script
echo.

:: Keep command window open.
pause
"@ -f $SqlScriptDatabaseName, $currentDateTime | Out-File -Encoding 'ASCII' -FilePath $sqlBatchFilePath

Write-Output ('')
Write-Output ('The operation completed successfully.')
Write-Output ('')

Stop-Transcript
