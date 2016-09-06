<#

Microsoft PowerShell

LiteSpeed Extractor for Microsoft SQL Server
Convert LiteSpeed Database Backups And Restore To Microsoft SQL Server
Created by William Chang

Created: 2014-08-25
Modified: 2015-01-09

LightSpeed Examples:
extractor.exe -F"lightspeed.bak" -E"mssql.bak" -N1

SQLCMD Examples:
sqlcmd.exe -x -i database.sql

PowerShell Examples:
powershell.exe Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
powershell.exe -File .\LiteSpeedExtractor_ConvertAndRestoreToMssql.ps1
powershell.exe -File C:\Temp\LiteSpeedExtractor_ConvertAndRestoreToMssql.ps1

References:
http://www.rubaniuk.com/?p=113
http://sqlserverpowershell.com/2012/07/03/powershell-script-to-extract-litespeed-databases/
http://personal-code.blogspot.com/2013/03/powershell-string-literals-and-formating.html
http://www.neolisk.com/techblog/powershell-specialcharactersandtokens
http://blogs.technet.com/b/heyscriptingguy/archive/2011/09/21/two-simple-powershell-methods-to-remove-the-last-letter-of-a-string.aspx
http://stackoverflow.com/questions/7089627/how-can-i-retrieve-the-logical-file-name-of-the-database-from-backup-file
http://www.mssqltips.com/sqlservertip/1966/function-to-return-default-sql-server-backup-folder/

#>

Clear-Host

$currentScriptName = 'PowerShell_Sandbox'
$currentDateTime = Get-Date -Format 'yyyyMMddHHmm'
$currentFolderPath = Get-Location

#Stop-Transcript | Out-Null
$logFileName = '{0}.{1}.log' -f $currentScriptName, $currentDateTime
$logFilePath = '{0}\{1}' -f $currentFolderPath, $logFileName
Start-Transcript -Path $logFilePath -Append

$executableSqlcmdPath = 'sqlcmd.exe'
$executableLightSpeedPath = '{0}\LiteSpeedExtractor.exe' -f $currentFolderPath
$lsFileSearchPath = '{0}\*.bak' -f $currentFolderPath
$lsConvertedFolderPath = '{0}\Converted_{1}' -f $currentFolderPath, $currentDateTime

Write-Host ("`n")
Write-Host ("Current Date And Time : {0}" -f $currentDateTime)
Write-Host ("Current Folder Path : {0}" -f $currentFolderPath)
Write-Host ("Executable LightSpeed Path : {0}" -f $executableLightSpeedPath)
Write-Host ("LightSpeed File Search Path : {0}" -f $lsFileSearchPath)
Write-Host ("LightSpeed Converted Folder Path : {0}" -f $lsConvertedFolderPath)
Write-Host ("`n")

Invoke-Expression -Command ('mkdir {0} -force' -f $lsConvertedFolderPath) | Out-Null

$lsbackupFiles = Get-ChildItem -Path $lsFileSearchPath

foreach($lsbackupFile in $lsbackupFiles)
{
    if(!$lsbackupFile)
    {
        Write-Host ("`n`nLightSpeed backup file not found.`n`n")
        exit
    }

    $lsConvertCommand = '{0} -F""{1}\{2}"" -E""{3}\{4}.mssql.bak"" -N1' -f $executableLightSpeedPath, $currentFolderPath, $lsbackupFile.Name, $lsConvertedFolderPath, $lsbackupFile.BaseName

    Write-Host ("`n`n")
    Write-Host ("LightSpeed Convert Command : {0}" -f $lsConvertCommand)
    Write-Host ("`n`n")

    Invoke-Expression -Command $lsConvertCommand

    $mssqlFileSearchPath = '{0}\{1}.mssql.bak*' -f $lsConvertedFolderPath, $lsbackupFile.BaseName

    Write-Host ("`n`n")
    Write-Host ("LightSpeed Backup File : {0}" -f $lsbackupFile.Name)
    Write-Host ("`n")
    $sqlDatabaseRestoreName = Read-Host "What database name to restore to your local MSSQL server?"
    Write-Host ("`n`n")
    if(!$sqlDatabaseRestoreName -or $sqlDatabaseRestoreName.length -lt 3)
    {
        Write-Host ("`n`nInvalid input of database name.`n`n")
        continue
    }

    Write-Host ("`n`n")
    Write-Host ("Executable SQLCMD Path : {0}" -f $executableSqlcmdPath)
    Write-Host ("SQL File Search Path : {0}" -f $mssqlFileSearchPath)
    Write-Host ("SQL Database Name : {0}" -f $sqlDatabaseRestoreName)
    Write-Host ("`n`n")

    try
    {
        Invoke-Expression -Command ("{0} -E -Q ""SET NOCOUNT ON;SELECT @@VERSION;"" -h-1" -f $executableSqlcmdPath)
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        Write-Host ("`n`nSQLCMD executable not found.`n`n")
        exit
    }

    $mssqlBackupFiles = Get-ChildItem -Path $mssqlFileSearchPath
    $mssqlLastBackupFilePath = ""
    $sqlRestoreDatabasePartialQuery = ""

    foreach($mssqlBackupFile in $mssqlBackupFiles)
    {
        if(!$mssqlBackupFile)
        {
            Write-Host ("`n`n`MSSQL backup file not found.`n`n")
            exit
        }
    
        $sqlRestoreDatabasePartialQuery += "DISK = '{0}', " -f $mssqlBackupFile.FullName
        $mssqlLastBackupFilePath = $mssqlBackupFile.FullName
    }

    $sqlDatabaseLogicalNamesQuery = "SET NOCOUNT ON;DECLARE @Table TABLE (LogicalName varchar(128),[PhysicalName] varchar(128), [Type] varchar, [FileGroupName] varchar(128), [Size] varchar(128), [MaxSize] varchar(128), [FileId]varchar(128), [CreateLSN]varchar(128), [DropLSN]varchar(128), [UniqueId]varchar(128), [ReadOnlyLSN]varchar(128), [ReadWriteLSN]varchar(128), [BackupSizeInBytes]varchar(128), [SourceBlockSize]varchar(128), [FileGroupId]varchar(128), [LogGroupGUID]varchar(128), [DifferentialBaseLSN]varchar(128), [DifferentialBaseGUID]varchar(128), [IsReadOnly]varchar(128), [IsPresent]varchar(128), [TDEThumbprint]varchar(128));DECLARE @Path varchar(1000) = '{1}';DECLARE @LogicalNameData varchar(128), @LogicalNameLog varchar(128);INSERT INTO @table EXEC('RESTORE FILELISTONLY FROM DISK=''' + @Path + '''');SET @LogicalNameData = (SELECT LogicalName FROM @Table WHERE Type = 'D');SET @LogicalNameLog = (SELECT LogicalName FROM @Table WHERE Type = 'L');SELECT @LogicalNameData + ',' + @LogicalNameLog;" -f $executableSqlcmdPath, $mssqlLastBackupFilePath
    $sqlDatabaseLogicalNamesCommand = "{0} -E -Q ""{1}"" -h-1 -W" -f $executableSqlcmdPath, $sqlDatabaseLogicalNamesQuery

    Write-Host ("`n`n")
    Write-Host ("SQL Last Backup File Path : {0}" -f $mssqlLastBackupFilePath)
    Write-Host ("SQL Get Database Logical Names Query : {0}" -f $sqlDatabaseLogicalNamesQuery)
    Write-Host ("SQL Get Database Logical Names Command : {0}" -f $sqlDatabaseLogicalNamesCommand)
    Write-Host ("`n`n")

    $sqlGetDatabaseLogicalNamesCommandOutput = Invoke-Expression -Command $sqlDatabaseLogicalNamesCommand | Out-String
    $sqlDatabaseLogicalNames = $sqlGetDatabaseLogicalNamesCommandOutput.trim() -split ','

    $sqlDefaultDataFolderPath = ''
    $sqlDefaultDataFolderPathOutput = Invoke-Expression -Command ("{0} -E -Q ""SET NOCOUNT ON;SELECT SERVERPROPERTY('InstanceDefaultDataPath');"" -h-1 -W" -f $executableSqlcmdPath) | Out-String
    if($sqlDefaultDataFolderPathOutput -like '*null*')
    {
        $sqlDefaultDataFolderPathOutput = Invoke-Expression -Command ("{0} -E -Q ""DECLARE @returnValue NVARCHAR(500);EXEC master..xp_instance_regread @rootkey = N'HKEY_LOCAL_MACHINE', @key = N'SOFTWARE\Microsoft\MSSQLServer\Setup', @value_name = N'SQLDataRoot', @value = @returnValue output;PRINT @returnValue;"" -h-1 -W" -f $executableSqlcmdPath) | Out-String
        $sqlDefaultDataFolderPathOutput = $sqlDefaultDataFolderPathOutput.trim() -replace '\\$'
        $sqlDefaultDataFolderPath = '{0}\DATA' -f $sqlDefaultDataFolderPathOutput
    } else
    {
        $sqlDefaultDataFolderPath = $sqlDefaultDataFolderPathOutput.trim() -replace '\\$'
    }

    $sqlRestoreDatabasePartialQuery = $sqlRestoreDatabasePartialQuery -replace '..$'
    $sqlRestoreDatabaseQuery = "RESTORE DATABASE {0} FROM {1} WITH RECOVERY, MOVE '{2}' TO '{4}\{0}.mdf', MOVE '{3}' TO '{4}\{0}_log.ldf';" -f $sqlDatabaseRestoreName, $sqlRestoreDatabasePartialQuery, $sqlDatabaseLogicalNames[0], $sqlDatabaseLogicalNames[1], $sqlDefaultDataFolderPath
    $sqlRestoreDatabaseCommand = "{0} -E -Q ""{1}""" -f $executableSqlcmdPath, $sqlRestoreDatabaseQuery

    Write-Host ("`n`n")
    Write-Host ("SQL Default Data Folder Path : {0}" -f $sqlDefaultDataFolderPath)
    Write-Host ("SQL Database Data Logicial Name : {0}" -f $sqlDatabaseLogicalNames[0])
    Write-Host ("SQL Database Log Logicial Name : {0}" -f $sqlDatabaseLogicalNames[1])
    Write-Host ("SQL Restore Database Query : {0}" -f $sqlRestoreDatabaseQuery)
    Write-Host ("SQL Restore Database Command : {0}" -f $sqlRestoreDatabaseCommand)
    Write-Host ("`n`n")

    Invoke-Expression -Command $sqlRestoreDatabaseCommand
}

Stop-Transcript
