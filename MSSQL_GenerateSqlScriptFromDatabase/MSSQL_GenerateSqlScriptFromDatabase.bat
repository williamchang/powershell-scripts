@echo off
setlocal enabledelayedexpansion

:: Generate SQL Script From Microsoft SQL Server Database

:: Batch Commands:
:: Get directory of batch file : %~dp0
:: Get file name in for-loop : %%~nf
:: Get file name and file type in for-loop : %%~nxf

echo.
echo BEGIN Script
echo.

:: Run operation.
echo.
echo BEGIN Operation
echo.

powershell.exe Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
powershell.exe -File .\MSSQL_GenerateSqlScriptFromDatabase.ps1

echo.
echo END Operation
echo.

:end
echo.
echo END Script
echo.

:: Keep command window open.
pause
