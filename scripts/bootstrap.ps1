#Requires -Version 5.1
<#
.SYNOPSIS
  补齐 MediaVault 目录结构。
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$dirs = @(
  "library\primary\asia",
  "library\primary\western",
  "library\primary\indie",
  "library\alternate\studios",
  "library\alternate\western",
  "library\alternate\indie",
  "library\_inbox",
  "config\providers",
  "metadata",
  "cache",
  "blobs",
  "generated",
  "presets",
  "docs",
  "scripts"
)

Write-Host "==> MediaVault bootstrap @ $Root" -ForegroundColor Cyan
foreach ($d in $dirs) {
  $p = Join-Path $Root $d
  if (-not (Test-Path $p)) {
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    Write-Host "  created $d"
  } else {
    Write-Host "  ok      $d"
  }
  $keep = Join-Path $p ".gitkeep"
  if (-not (Test-Path $keep)) {
    New-Item -ItemType File -Path $keep -Force | Out-Null
  }
}

if (-not (Test-Path (Join-Path $Root ".env")) -and (Test-Path (Join-Path $Root ".env.example"))) {
  Write-Host ""
  Write-Host "提示：可复制 .env.example 为 .env 并修改 MV_HOST_PORT。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "下一步：" -ForegroundColor Green
Write-Host "  .\scripts\start.ps1"
Write-Host "  浏览器打开 http://localhost:9999"
Write-Host "  添加库路径 /data/primary 与 /data/alternate （见 presets\libraries.json.example）"
