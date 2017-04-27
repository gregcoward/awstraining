 param (
    [string]$dbserver,
    [securestring]$password,
    [string]$username,
    [string]$zipfile
 )

Add-Type -AssemblyName System.IO.Compression.FileSystem

##  Create user and add to Administrators group
$pass = ConvertTo-SecureString $password -AsPlainText -Force
New-LocalUser -Name $username -Password $pass -PasswordNeverExpires
Add-LocalGroupMember -Group \"Administrators\" -Member $username

## Functions
function instTools {
    Invoke-WebRequest https://raw.githubusercontent.com/gregcoward/awstraining/master/MsSqlCmdLnUtils.msi -OutFile c:\users\$username\downloads\MsSqlCmdLnUtils.msi
    Invoke-WebRequest https://raw.githubusercontent.com/gregcoward/awstraining/master/msodbcsql.msi -OutFile C:\Users\$username\downloads\msodbcsql.msi
    msiexec.exe /i "C:\Users\$username\downloads\msodbcsql.msi" /qn IACCEPTMSODBCSQLLICENSETERMS=YES
    msiexec /i "c:\users\$username\downloads\MsSqlCmdLnUtils.msi" /qn IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES
}

function createDb {
    & 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -E -S localhost -Q "CREATE LOGIN [$env:COMPUTERNAME\$username] FROM WINDOWS WITH DEFAULT_DATABASE=[master]"
    & 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -E -S localhost -Q "EXEC [sys].[sp_addsrvrolemember] @loginame = N'$env:COMPUTERNAME\$username', @rolename = N'sysadmin'"
    & 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -E -S localhost -Q "CREATE DATABASE nopcomm"
}

##  Check if we are the DB server or are a webserver ...
$serverType = $(Test-Path C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE)

if ($serverType -eq $True) {
    ## Then we are the database server
}
else {
    ## Then we are a webserver
}


$sqlExist = $(& 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -S tcp:$dbserver,1433 -Q "IF DB_ID('nopcomm') IS NOT NULL BEGIN PRINT 'Database Exists' END")
if (!$sqlExist) {
    Unzip "C:\a.zip" "C:\inetpub\wwwroot\"
}

function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}