$pass = ConvertTo-SecureString "SomePassword" -AsPlainText -Force
New-LocalUser -Name "tstanley" -Password $pass -PasswordNeverExpires
Add-LocalGroupMember -Group \"Administrators\" -Member "tstanley"
sqlcmd -E -S localhost -Q "CREATE LOGIN [$env:COMPUTERNAME\tstanley] FROM WINDOWS WITH DEFAULT_DATABASE=[master]"
sqlcmd -E -S localhost -Q "EXEC [sys].[sp_addsrvrolemember] @loginame = N'$env:COMPUTERNAME\tstanley', @rolename = N'sysadmin'"
sqlcmd -E -S localhost -Q "CREATE DATABASE nopcomm"
$sqlExist = $(sqlcmd -E -S tcp:<computerName>,1433 -Q "IF DB_ID('nopcomm') IS NOT NULL BEGIN PRINT 'Database Exists' END")
if (!$sqlExist) {

}



Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\a.zip" "C:\inetpub\wwwroot\"