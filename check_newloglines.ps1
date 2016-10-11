# Aaron Gorka 28/07/2016
<#
.SYNOPSIS 
    Monitoring plugin to count the number of new lines in a log.
.DESCRIPTION 
    Counts the number of lines in a log, saves that number to a temporary file and then compares it with the previous check. Any number > 0 is considered OK.
.NOTES 
    Author     : Aaron Gorka 2016/07/28
    Rewrite of script from https://exchange.nagios.org/directory/Plugins/Email-and-Groupware/Microsoft-Exchange/Exchange-Database-mount-check-2E/details
.EXAMPLE
    ./check_newloglines.ps1 -Path "C:\Program Files\NSClient\nsclient.log"
#>
# 
Param(
  [string]$Path = "C:\Program Files\NSClient\nsclient.log"
)

$error.clear()
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

function Get-CompatibleHash
{
    # hash method that works in Powershell v2
    $enc = [system.Text.Encoding]::UTF8
    $data1 = $enc.GetBytes($args[0]) 
    $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider 
    [System.BitConverter]::ToString( $sha1.ComputeHash($data1)).ToLower().Replace("-","")
 }

try {
    $PathHash = Get-CompatibleHash $Path
}
catch {
    Write-Host -NoNewLine "UNKNOWN: error accessing $Path. $Error"
    exit 3
}

try {
    $Previous = Get-Content "$env:TEMP/check_newloglines_$PathHash"
}
catch {
    "Initialising" | Out-File "$env:TEMP/check_newloglines_$PathHash"
    $Previous = 0
}

try {
    $Current = (Get-Content $Path | Measure-Object).count
}
catch {
    Write-Host -NoNewLine "UNKNOWN: error accessing $Path. $Error"
    exit 3
}

try {
    $Current | Out-File -FilePath "$env:TEMP/check_newloglines_$PathHash"
}
Catch {
    Write-Host -NoNewLine "UNKNOWN: error writing to $Current. $Error"
    exit 3
}

try {
    $Difference = $Current - $Previous
}
catch {
    Write-Host -NoNewLine "UNKNOWN: error calculating new line count. $Error"
    exit 3
}

if ($Difference -eq 0){
    Write-Host -NoNewLine "CRITICAL: $Path has $Difference new lines|'new lines'=${Difference}lines 'previous lines'=${Previous}lines 'current lines'=${Current}lines"
    exit 2
}
elseif ($Difference -ge 1){
    Write-Host -NoNewLine "OK: $Path has $Difference new lines|'new lines'=${Difference}lines 'previous lines'=${Previous}lines 'current lines'=${Current}lines"
    exit 0
}
else {
    Write-Host -NoNewLine "UNKNOWN: internal plugin error"
    exit 3
}
