#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "==> MediaVault: docker compose down @ $Root" -ForegroundColor Cyan
docker compose down
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "已停止。" -ForegroundColor Green
