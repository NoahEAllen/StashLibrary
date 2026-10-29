#Requires -Version 5.1
<#
.SYNOPSIS
  Watch configured media roots (TEMP/cloud/downloads + optional inbox).
  On change, call auto-scan.ps1 with matching container paths (no Rescan).
#>
param(
  [int]$Interval = 0,
  [switch]$Once,
  [switch]$IncludeInbox
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $Root ".env"
$StateFile = Join-Path $Root "cache\_media-watch.state"
$exts = @(".mp4",".mkv",".avi",".wmv",".mov",".m4v",".ts",".m2ts",".webm",".zip",".rar",".7z",".jpg",".jpeg",".png",".webp",".gif")

function Get-DotEnv([string]$path) {
  $map = @{}
  if (-not (Test-Path $path)) { return $map }
  Get-Content $path | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    $i = $line.IndexOf("=")
    if ($i -lt 1) { return }
    $k = $line.Substring(0, $i).Trim()
    $v = $line.Substring($i + 1).Trim().Trim('"').Trim("'")
    $map[$k] = $v
  }
  return $map
}

function Convert-ToHostPath([string]$p) {
  if (-not $p) { return $p }
  return ($p -replace '/', '\')
}

$envMap = Get-DotEnv $EnvFile
if ($Interval -le 0) {
  $iv = $envMap["MV_WATCH_INTERVAL"]
  if ($iv) { $Interval = [int]$iv } else { $Interval = 60 }
}
$includeInboxEnv = $envMap["MV_WATCH_INCLUDE_INBOX"]
if ($IncludeInbox -or ($includeInboxEnv -and $includeInboxEnv -match '^(1|true|yes)$')) {
  $IncludeInbox = $true
}

# Host path -> container path for selective scan
$watchPairs = @()
function Add-WatchPair([string]$hostPath, [string]$containerPath) {
  if (-not $hostPath) { return }
  $hp = Convert-ToHostPath $hostPath
  if (-not (Test-Path -LiteralPath $hp)) {
    Write-Warning "skip missing host path: $hp"
    return
  }
  $script:watchPairs += [pscustomobject]@{ Host = $hp; Container = $containerPath }
}

Add-WatchPair $envMap["MV_MEDIA_TEMP"] "/data/primary/sources/temp"
Add-WatchPair $envMap["MV_MEDIA_CLOUD"] "/data/primary/sources/cloud"
Add-WatchPair $envMap["MV_MEDIA_DL"] "/data/alternate/sources/downloads"
if ($IncludeInbox) {
  Add-WatchPair (Join-Path $Root "library\_inbox") "/data/_inbox"
}

if (-not $watchPairs.Count) {
  Write-Error "No watch roots. Set MV_MEDIA_TEMP / MV_MEDIA_CLOUD / MV_MEDIA_DL in .env (and/or -IncludeInbox)."
  exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $StateFile) | Out-Null

function Get-RootsFingerprint {
  $sb = New-Object System.Text.StringBuilder
  foreach ($pair in $watchPairs) {
    $files = Get-ChildItem -LiteralPath $pair.Host -File -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $exts -contains $_.Extension.ToLowerInvariant() }
    [void]$sb.AppendLine("ROOT|$($pair.Container)")
    if ($files) {
      $files | Sort-Object FullName | ForEach-Object {
        [void]$sb.AppendLine("$($_.LastWriteTimeUtc.Ticks)|$($_.Length)|$($_.FullName)")
      }
    }
  }
  $bytes = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
  } finally { $sha.Dispose() }
}

$pathsArg = ($watchPairs | ForEach-Object { $_.Container }) -join ","
$last = ""
if (Test-Path $StateFile) { $last = (Get-Content $StateFile -Raw).Trim() }

Write-Host "watch-media: interval=${Interval}s roots=$pathsArg"
while ($true) {
  $cur = Get-RootsFingerprint
  if ($cur -and $cur -ne $last) {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') media roots changed -> auto-scan $pathsArg"
    try {
      & (Join-Path $PSScriptRoot "auto-scan.ps1") -Paths $pathsArg
      Set-Content -Path $StateFile -Value $cur -NoNewline
      $last = $cur
    } catch {
      Write-Warning "auto-scan failed; will retry: $_"
    }
  } else {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') no change"
  }
  if ($Once) { break }
  Start-Sleep -Seconds $Interval
}
