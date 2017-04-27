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

#region Functions
function instTools ($username) {
    Invoke-WebRequest "https://raw.githubusercontent.com/gregcoward/awstraining/master/MsSqlCmdLnUtils.msi" -OutFile "c:\users\$username\downloads\MsSqlCmdLnUtils.msi"
    Invoke-WebRequest "https://raw.githubusercontent.com/gregcoward/awstraining/master/msodbcsql.msi" -OutFile "C:\Users\$username\downloads\msodbcsql.msi"
    msiexec.exe /i "C:\Users\$username\downloads\msodbcsql.msi" /qn IACCEPTMSODBCSQLLICENSETERMS=YES
    msiexec /i "c:\users\$username\downloads\MsSqlCmdLnUtils.msi" /qn IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES
}

function createDb ($username) {
    & 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -E -S localhost -Q "CREATE LOGIN [$env:COMPUTERNAME\$username] FROM WINDOWS WITH DEFAULT_DATABASE=[master]"
    & 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -E -S localhost -Q "EXEC [sys].[sp_addsrvrolemember] @loginame = N'$env:COMPUTERNAME\$username', @rolename = N'sysadmin'"
    & 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -E -S localhost -Q "CREATE DATABASE nopcomm"
}

function Unzip {
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
#endregion
##  Check if we are the DB server or are a webserver ...
$serverType = $(Test-Path C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE)

if ($serverType -eq $True) {
    ## Then we are the database server
    ## Add user and create the database.
    createDb $username
    exit 
}
else {
    ## Then we are a webserver
    ## Install SQL Tools
    instTools $username

    ## Wait until Database Server and Database exist, then install nopComm
    $i = 0
    do {
        $sqlExist = $(& 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE' -S tcp:$dbserver,1433 -Q "IF DB_ID('nopcomm') IS NOT NULL BEGIN PRINT 'Database Exists' END")
        if (!$sqlExist) {
            ## Download the file:
            Invoke-WebRequest https://raw.githubusercontent.com/gregcoward/awstraining/master/nopCommerce_3.90_NoSource.zip -OutFile c:\users\$username\downloads\nopCommerce_3.90_NoSource.zip
            Unzip "c:\users\$username\downloads\nopCommerce_3.90_NoSource.zip" "C:\inetpub\wwwroot\"
            $i = 1
        }
        else {
            Write-Host "Sleeping for 10 Seconds"
            Start-Sleep -Seconds 10
        }
    } while ($i -eq 0)
}
