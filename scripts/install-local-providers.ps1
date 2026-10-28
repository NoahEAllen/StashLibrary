#Requires -Version 5.1
<#
.SYNOPSIS
  将 config/providers-src/* 复制到 config/providers/（本地自定义 provider）。
#>
param(
  [string]$Dest = ""
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Src = Join-Path $Root "config\providers-src"
if (-not $Dest) { $Dest = Join-Path $Root "config\providers" }

if (-not (Test-Path $Src)) {
  Write-Error "缺少本地源目录: $Src"
  exit 1
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$count = 0
Get-ChildItem -Path $Src -Directory | ForEach-Object {
  $name = $_.Name
  $target = Join-Path $Dest $name
  if (Test-Path $target) { Remove-Item -Recurse -Force $target }
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  Copy-Item -Path (Join-Path $_.FullName "*") -Destination $target -Recurse -Force
  Write-Host "installed local provider: $name -> $target"
  $count++
}

if ($count -eq 0) {
  Write-Error "providers-src 下没有可安装的子目录"
  exit 1
}
Write-Host "done: $count local provider package(s). Reload providers in UI."
