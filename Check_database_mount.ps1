<#
.SYNOPSIS 
    Monitoring plugin to check that all Exchange databases are mounted and healthy.
.DESCRIPTION 
    Monitors Exchange database mount status via Get-MailboxDatabaseCopyStatus. Checks both the Status and ContentIndexState properties.
.NOTES 
    Author     : Aaron Gorka 2016/09/26
    Rewrite of script from https://exchange.nagios.org/directory/Plugins/Email-and-Groupware/Microsoft-Exchange/Exchange-Database-mount-check-2E/details
.EXAMPLE
    ./Check_database_mount.ps1
#>

$error.clear()
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

try {
    if ( (Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction:SilentlyContinue) -eq $null)
    {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
    }
}
catch {
    Write-Host -NoNewline "UNKNOWN: error loading snap-in. $error"
    exit 3
}

try {
    $DBStatus = Get-MailboxDatabaseCopyStatus *
}
catch {
    Write-Host -NoNewline "UNKNOWN: error running command 'Get-MailboxDatabaseCopyStatus'. $error"
    exit 3
}

$indexErrorDB = ""
$errorDB = ""
foreach ($database in $DBStatus){
    if (!($database.Status -eq "Mounted" -or $database.Status -eq "Healthy")){
        $errorDB += $database
    }
    if (!($database.ContentIndexState -eq "Healthy")){
        $indexErrorDB += $database
    }
}

if ($errorDB){
    $stdout = "CRITICAL: "
    foreach ($err in $errorDB){
        $stdout += "database '$($err.Name)' status is $($err.Status), "
    }

    foreach ($err in $indexErrorDB){
        $stdout += "database '$($err.Name)' ContentIndexState is $($err.ContentIndexState), "
    }
    
    $stdout = $stdout.TrimEnd(","," ")
    $stdout += "."
    
    Write-Host -NoNewline "$stdout"
    exit 1
} else {
    $stdout = "OK: all databases are mounted and healthy."
    Write-Host -NoNewline "$stdout"
    exit 0
}