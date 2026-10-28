#Requires -Version 5.1
<#
.SYNOPSIS
  轮询 library\_inbox；发现新媒体则调用 auto-scan（默认 /data/_inbox）。
#>
param(
  [int]$Interval = 60,
  [switch]$Once
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Inbox = Join-Path $Root "library\_inbox"
$StateFile = Join-Path $Root "cache\_inbox-watch.state"
$exts = @(".mp4",".mkv",".avi",".wmv",".mov",".m4v",".ts",".m2ts",".webm")

New-Item -ItemType Directory -Force -Path (Split-Path $StateFile) | Out-Null
New-Item -ItemType Directory -Force -Path $Inbox | Out-Null

function Get-InboxFingerprint {
  $files = Get-ChildItem -Path $Inbox -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $exts -contains $_.Extension.ToLowerInvariant() }
  if (-not $files) { return "" }
  $sb = New-Object System.Text.StringBuilder
  $files | Sort-Object FullName | ForEach-Object {
    [void]$sb.AppendLine("$($_.LastWriteTimeUtc.Ticks)|$($_.Length)|$($_.FullName)")
  }
  $bytes = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
  } finally { $sha.Dispose() }
}

$last = ""
if (Test-Path $StateFile) {
  $last = (Get-Content $StateFile -Raw).Trim()
}

Write-Host "watch-inbox: $Inbox (interval=${Interval}s)"
while ($true) {
  $cur = Get-InboxFingerprint
  if ($cur -and $cur -ne $last) {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') inbox changed -> auto-scan /data/_inbox"
    try {
      & (Join-Path $PSScriptRoot "auto-scan.ps1") -Paths "/data/_inbox"
      Set-Content -Path $StateFile -Value $cur -NoNewline
      $last = $cur
    } catch {
      Write-Warning "auto-scan 失败，下轮重试: $_"
    }
  } else {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') no new media (or empty)"
  }
  if ($Once) { break }
  Start-Sleep -Seconds $Interval
}
