#Requires -Version 5.1
<#
.SYNOPSIS
  git pull（若是 git 仓）+ docker compose pull + up -d；默认顺带刷新 providers。
.PARAMETER SkipProviders
  跳过 install-providers。
#>
param(
  [switch]$SkipProviders
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "==> MediaVault update @ $Root" -ForegroundColor Cyan

$gitDir = Join-Path $Root ".git"
$haveGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
if ((Test-Path $gitDir) -and $haveGit) {
  Write-Host "==> git pull" -ForegroundColor Cyan
  git pull --ff-only
  if ($LASTEXITCODE -ne 0) {
    git pull
    if ($LASTEXITCODE -ne 0) { throw "git pull 失败" }
  }
} else {
  Write-Host "==> 非 git 仓或无 git，跳过 git pull" -ForegroundColor DarkGray
}

if (-not $SkipProviders) {
  Write-Host "==> install-providers (Profile=all)" -ForegroundColor Cyan
  & (Join-Path $PSScriptRoot "install-providers.ps1") -Profile all
} else {
  Write-Host "==> 跳过 providers（-SkipProviders）" -ForegroundColor DarkGray
}

Write-Host "==> docker compose pull" -ForegroundColor Cyan
docker compose pull
# pull 失败不阻断（镜像源问题等），仍尝试 up
Write-Host "==> ensure env + up -d" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "start.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "更新完成。" -ForegroundColor Green
