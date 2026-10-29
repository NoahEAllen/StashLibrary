#Requires -Version 5.1
param(
  [string]$Csv = "",
  [string]$Status = "pending"
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if (-not $Csv) {
  $cand = Join-Path $Root "cache\performer-wishlist.csv"
  if (Test-Path $cand) { $Csv = $cand }
  else { $Csv = Join-Path $Root "presets\performer-wishlist.csv.example" }
}
if (-not (Test-Path $Csv)) { Write-Error "CSV not found: $Csv"; exit 1 }
$rows = Import-Csv -LiteralPath $Csv
$filtered = $rows | Where-Object { $_.status -eq $Status }
Write-Host "file: $Csv  status=$Status  count=$($filtered.Count)"
$filtered | ForEach-Object {
  "{0}`t{1}`t{2}" -f $_.performer, $_.title_or_code, $_.notes
}
