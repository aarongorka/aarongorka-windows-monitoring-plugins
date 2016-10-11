<#
.SYNOPSIS 
    Monitoring plugin for monitoring quota usage
.DESCRIPTION 
    Monitors Quota usage via Get-FsrmQuota
.NOTES 
    Author     : Aaron Gorka 2016/09/20
.PARAMETER Path
    The path to the folder on which a quota is applied
.PARAMETER Crit
    The percentage of quota free at which we should exit with CRITICAL
.PARAMETER Warn
    The percentage of quota free at which we should exit with WARNING
.EXAMPLE
    ./check_quota.ps1 -Path "D:\Shares\files" -Warn 20 -Crit 10
#>

Param(
  [int]$crit = 20,
  [int]$warn = 10,
  [string]$Path
)

$error.Clear()
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

Try {
    Test-Path $Path -pathType container | Out-Null
}
Catch {
    Write-Host -NoNewLine "UNKNOWN: '${Path}' is not a folder or cannot be accessed. $error"
    exit 3
}

Try {
    $quotaObject = Get-FsrmQuota -Path $Path
}
Catch {
    Write-Host -NoNewLine "UNKNOWN: $error"
    exit 3
}

If (!$quotaObject){
    Write-Host -NoNewLine "UNKNOWN: 'Get-FsrmQuota' returned a null value."
    exit 3
}

If (!$quotaObject.Size){
    Write-Host -NoNewLine "UNKNOWN: no quota set, nothing to monitor."
    exit 3
}

try {
    $gbUsage = "{0:n2} GB" -f ($quotaObject.Usage / 1GB)
    $gbLimit = "{0:n2} GB" -f ($quotaObject.Size / 1GB)
    $percentUsed = "{0:n2}" -f ($quotaObject.Usage / $quotaObject.Size * 100)
    $percentFree = "{0:n2}" -f (100 - $quotaObject.Usage / $quotaObject.Size * 100)
    $percentFreeFloat = 100 - $quotaObject.Usage / $quotaObject.Size * 100 # the value returned above does not work in comparisons for some reason...
    $critBytes = $quotaObject.Size - ($quotaObject.Size * $crit / 100)
    $warnBytes = $quotaObject.Size - ($quotaObject.Size * $warn / 100)
    $perfData = "usage=$($quotaObject.Usage)B;$warnBytes;$critBytes;0;$($quotaObject.Size) limit=$($quotaObject.Size)B;;;;"
}
Catch {
    Write-Host -NoNewLine "UNKNOWN: internal plugin error calculating values. $error"
    exit 3
}

if ($percentFreeFloat -le $crit){
    Write-Host -NoNewLine "CRITICAL: $gbUsage of $gbLimit used, ${percentFree}% free.|$perfData"
    exit 2
} elseif ($percentFreeFloat -le $warn){
    Write-Host -NoNewLine "WARNING: $gbUsage of $gbLimit used, ${percentFree}% free.|$perfData"
    exit 1
} elseif ($percentFreeFloat -gt $warn) {
    Write-Host -NoNewLine "OK: $gbUsage of $gbLimit used, ${percentFree}% free.|$perfData"
    exit 0
} else {
    Write-Host -NoNewLine "UNKNOWN: an internal plugin error occurred."
    exit 3
}
