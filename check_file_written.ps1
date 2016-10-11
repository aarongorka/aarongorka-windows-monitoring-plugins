# Aaron Gorka 28/07/2016
# Checks the most recently written to file and alerts if it is older than the thresholds in minutes.
# NB: largely untested due to file timestamps being an unreliable indicator of whether or not a file has been modified.
Param(
  [int]$crit = 20,
  [int]$warn = 10,
  [string]$Path = $Env:temp
)

$error.clear()
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

Try {
    Test-Path $Path | Out-Null
}
Catch {
    Write-Host -NoNewLine "UNKNOWN: '${Path}' is not a path or cannot be accessed. $error"
    exit 3
}

Try {
    $File = Get-ChildItem $Path | Where-Object { -not $_.PsIsContainer } | sort LastWriteTime | Select-Object -Last 1
}
Catch {
    Write-Host -NoNewLine "UNKNOWN: Error accessing files in ${Path}. $error"
    exit 3
}

Try {
    $Written = $File.LastWriteTime
    $WrittenMinutesAgo = ((get-date) - $Written).Minutes
}
Catch {
    Write-Host -NoNewLine "UNKNOWN: Error calculating time. $error"
    exit 3
}

if ($WrittenMinutesAgo -gt $crit)
{
    Write-Host -NoNewLine "CRITICAL: The most recently written to file in $Path was written to $WrittenMinutesAgo minutes ago|'last updated'=${WrittenMinutesAgo}m"
    exit 2
}
elseif ($WrittenMinutesAgo -gt $warn)
{
    Write-Host -NoNewLine "CRITICAL: The most recently written to file in $Path was written to $WrittenMinutesAgo minutes ago|'last updated'=${WrittenMinutesAgo}m"
    exit 1
}
elseif ($WrittenMinutesAgo -le $warn)
{
    Write-Host -NoNewline "OK: The most recently written to file in $Path was written to $WrittenMinutesAgo minutes ago|'last updated'=${WrittenMinutesAgo}m"
    exit 0
}
else {
    Write-Host -NoNewLine "UNKNOWN: Internal plugin error. $error"
    exit 3
}
