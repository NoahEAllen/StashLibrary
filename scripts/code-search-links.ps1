#Requires -Version 5.1
<#
.SYNOPSIS
  From a catalog code / title / path, print metadata-site search URLs (manual open).
  Uses asia-catalog Python helper (links mode). Does not scrape tube sites.
#>
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Query,
  [switch]$Open
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Py = Join-Path $Root "config\providers-src\asia-catalog\asia_catalog.py"
if (-not (Test-Path $Py)) {
  Write-Error "missing $Py — run from MediaVault repo root layout"
  exit 1
}
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pyCmd) { $pyCmd = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $pyCmd) { Write-Error "python/python3 required"; exit 1 }

$json = (@{ name = $Query } | ConvertTo-Json -Compress)
$out = $json | & $pyCmd.Source $Py links 2>$null
if (-not $out) { Write-Error "no catalog code / links for: $Query"; exit 1 }
$data = $out | ConvertFrom-Json
Write-Host "code: $($data.code)"
foreach ($u in $data.urls) {
  Write-Host $u
  if ($Open) { Start-Process $u }
}
