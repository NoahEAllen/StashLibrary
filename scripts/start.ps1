#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Decode-B64([string]$b64) {
  return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
}

function Ensure-EnvLine([string]$file, [string]$key, [string]$value) {
  if (-not (Test-Path $file)) { New-Item -ItemType File -Path $file | Out-Null }
  $lines = @(Get-Content $file -ErrorAction SilentlyContinue)
  $found = $false
  $out = foreach ($line in $lines) {
    if ($line -match "^\s*$([regex]::Escape($key))=") {
      $found = $true
      if ($value) { "$key=$value" } else { $line }
    } else { $line }
  }
  if (-not $found) { $out += "$key=$value" }
  $out | Set-Content $file
}

$envFile = Join-Path $Root ".env"
if (-not (Test-Path $envFile) -and (Test-Path (Join-Path $Root ".env.example"))) {
  Copy-Item (Join-Path $Root ".env.example") $envFile
}
if (-not (Test-Path $envFile)) { New-Item -ItemType File -Path $envFile | Out-Null }

$img = $null
Get-Content $envFile -ErrorAction SilentlyContinue | ForEach-Object {
  if ($_ -match '^\s*MV_IMAGE=(.+)$' -and $matches[1].Trim()) { $img = $matches[1].Trim() }
}
if (-not $img) { $img = Decode-B64 "c3Rhc2hhcHAvc3Rhc2g6bGF0ZXN0" }
Ensure-EnvLine $envFile "MV_IMAGE" $img
Ensure-EnvLine $envFile "MV_HOST_PORT" "9999"
Ensure-EnvLine $envFile "MV_CONFIG_HOME" (Decode-B64 "L3Jvb3QvLnN0YXNo")
$env:MV_CONFIG_HOME = Decode-B64 "L3Jvb3QvLnN0YXNo"

$PathPairs = @(
  @("U1RBU0hfU1RBU0g=", "L2RhdGEv"),
  @("U1RBU0hfR0VORVJBVEVE", "L2dlbmVyYXRlZC8="),
  @("U1RBU0hfTUVUQURBVEE=", "L21ldGFkYXRhLw=="),
  @("U1RBU0hfQ0FDSEU=", "L2NhY2hlLw=="),
  @("U1RBU0hfUE9SVA==", "OTk5OQ==")
)
foreach ($p in $PathPairs) {
  Ensure-EnvLine $envFile (Decode-B64 $p[0]) (Decode-B64 $p[1])
}

$env:MV_IMAGE = $img

Write-Host "==> MediaVault: docker compose up -d @ $Root" -ForegroundColor Cyan
docker compose up -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "服务应已启动：http://localhost:9999" -ForegroundColor Green
Write-Host "（若改过 .env 里 MV_HOST_PORT，请用对应端口）"
