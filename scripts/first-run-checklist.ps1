#Requires -Version 5.1
<#
.SYNOPSIS
  打印首次部署勾选清单（不启动 Docker）。可选 -OpenDocs 用记事本打开 docs/setup.md。
#>
param(
  [switch]$OpenDocs
)

$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
$SetupDoc = Join-Path $Root "docs\setup.md"

function Mark([bool]$ok, [string]$label) {
  if ($ok) {
    Write-Host "[x] $label" -ForegroundColor Green
  } else {
    Write-Host "[ ] $label" -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "==== MediaVault 首次部署清单 ====" -ForegroundColor Cyan
Write-Host "根目录: $Root"
Write-Host ""

$hasBootstrap = Test-Path (Join-Path $Root "scripts\bootstrap.ps1")
$hasEnvExample = Test-Path (Join-Path $Root ".env.example")
$hasEnv = Test-Path (Join-Path $Root ".env")
$hasPrimary = Test-Path (Join-Path $Root "library\primary")
$hasAlternate = Test-Path (Join-Path $Root "library\alternate")
$hasProvidersDir = Test-Path (Join-Path $Root "config\providers")
$hasAsiaCatalog = Test-Path (Join-Path $Root "config\providers-src\asia-catalog")
$hasAutoScan = Test-Path (Join-Path $Root "scripts\auto-scan.ps1")
$hasCompose = Test-Path (Join-Path $Root "docker-compose.yml")
$hasSetup = Test-Path $SetupDoc

Write-Host "-- 仓库结构 --" -ForegroundColor DarkCyan
Mark $hasBootstrap   "scripts/bootstrap.ps1 存在"
$hasBootstrapSh = Test-Path (Join-Path $Root "scripts\bootstrap.sh")
Mark $hasBootstrapSh "scripts/bootstrap.sh 存在（Linux/macOS）"
Mark $hasCompose     "docker-compose.yml 存在"
Mark $hasEnvExample  ".env.example 存在"
Mark $hasPrimary     "library/primary 存在"
Mark $hasAlternate   "library/alternate 存在"
Mark $hasProvidersDir "config/providers 存在"
Mark $hasAsiaCatalog "config/providers-src/asia-catalog 存在"
Mark $hasAutoScan    "scripts/auto-scan.ps1 存在"
Mark $hasSetup       "docs/setup.md 存在"

Write-Host ""
Write-Host "-- 建议操作顺序（勾选自用）--" -ForegroundColor DarkCyan
Write-Host " 1. .\scripts\bootstrap.ps1"
Write-Host " 2. 确认 .env（无则由 start.ps1 从 .env.example 生成）"
Mark $hasEnv         "    当前已有 .env"
Write-Host " 3. .\scripts\start.ps1"
Write-Host " 4. 浏览器打开 http://localhost:9999（或 MV_HOST_PORT）"
Write-Host " 5. UI 添加两个库路径："
Write-Host "       Primary   → /data/primary"
Write-Host "       Alternate → /data/alternate"
Write-Host " 6. Settings → 将 Providers Path 指向配置家目录下的 providers"
Write-Host "    （与本仓库 config/providers 对应；键名由 start.ps1 解码写入 .env）"
Write-Host " 7. 安装索引包："
Write-Host "       UI Community (stable)  或"
Write-Host "       .\scripts\install-providers.ps1 -Profile all"
Write-Host "       .\scripts\install-providers.ps1 -Profile primary"
Write-Host "       .\scripts\install-providers.ps1 -Profile alternate"
Write-Host " 8. （可选）.\scripts\install-local-providers.ps1  # asia-catalog 骨架"
Write-Host " 9. UI 中 Reload providers"
Write-Host "10. 对两个 Library 执行 Scan（勾选 Images；开启文件夹成册；图册放 library/*/albums）；或配置 API Key 后用 auto-scan："
Write-Host "       UI → Settings → 生成 API Key → 写入 .env 的 MV_API_KEY"
Write-Host "       .\scripts\auto-scan.ps1"
Write-Host "       .\scripts\watch-inbox.ps1 -Once   # 可选：监视 _inbox"
Write-Host "11. .\scripts\sanity-check.ps1（可选）"
Write-Host "12. 日常：.\scripts\update.ps1   （可选 -SkipProviders；Linux 用 update.sh）"

Write-Host ""
Write-Host "跳过日志（安装后）：config/providers/_skip-log.txt（已 gitignore）" -ForegroundColor DarkGray
Write-Host ""

if ($OpenDocs) {
  if (-not $hasSetup) {
    Write-Host "找不到 docs/setup.md，无法打开。" -ForegroundColor Red
    exit 1
  }
  $notepad = Get-Command notepad.exe -ErrorAction SilentlyContinue
  if ($notepad) {
    Start-Process notepad.exe -ArgumentList $SetupDoc
    Write-Host "已用 notepad 打开 docs/setup.md" -ForegroundColor Green
  } else {
    # non-Windows fallback: print path
    Write-Host "本机无 notepad；请手动打开：$SetupDoc" -ForegroundColor Yellow
    if (Get-Command xdg-open -ErrorAction SilentlyContinue) {
      Start-Process $SetupDoc
    }
  }
}

Write-Host "==== 清单结束 ====" -ForegroundColor Cyan
Write-Host ""
