#Requires -Version 5.1
<#
.SYNOPSIS
  从社区元数据仓库拉取精选 providers 到 config/providers。
  包名优先读 presets/provider-list.b64.txt（与 .sh 共用）；否则回退内嵌 PrimaryB64/AlternateB64。
  上游 URL 均为 Base64；缺失项跳过并写入 config/providers/_skip-log.txt。

.PARAMETER Profile
  primary | alternate | all（默认 all）
#>
param(
  [ValidateSet('primary', 'alternate', 'all')]
  [string]$Profile = 'all',
  [string]$Dest = "",
  [string]$WorkDir = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if (-not $Dest) { $Dest = Join-Path $Root "config\providers" }
if (-not $WorkDir) { $WorkDir = Join-Path $env:TEMP "mv-community-meta" }
$ListFile = Join-Path $Root "presets\provider-list.b64.txt"

function Decode-Name([string]$b64) {
  return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
}

function Read-SharedList([string]$path) {
  $primary = New-Object System.Collections.Generic.List[string]
  $alternate = New-Object System.Collections.Generic.List[string]
  if (-not (Test-Path $path)) { return @{ Primary = @(); Alternate = @() } }
  $section = ""
  Get-Content $path | ForEach-Object {
    $line = $_
    if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^\s*#') {
      if ($line -match '---\s*primary\s*---') { $section = 'primary' }
      elseif ($line -match '---\s*alternate\s*---') { $section = 'alternate' }
      return
    }
    $tok = $line.Trim()
    if (-not $tok) { return }
    if ($section -eq 'primary') { [void]$primary.Add($tok) }
    elseif ($section -eq 'alternate') { [void]$alternate.Add($tok) }
  }
  return @{ Primary = @($primary); Alternate = @($alternate) }
}

# --- embedded fallback (Base64 only; kept in sync with presets/provider-list.b64.txt) ---
$PrimaryB64 = @(
  "SmF2TGlicmFyeS55bWw=",
  "SmF2TGlicmFyeV9weXRob24=",
  "SmF2QnVzLnltbA==",
  "amF2ZGIueW1s",
  "amF2ZGJfemgueW1s",
  "SmF2RGF0YWJhc2UueW1s",
  "UjE4LmRldi55bWw=",
  "SUFGRA==",
  "QWR1bHRFbXBpcmUueW1s",
  "QnJhenplcnM=",
  "QmFuZ0Jyb3M=",
  "QWR1bHRUaW1l",
  "RmFrZUh1Yg==",
  "RXZpbEFuZ2Vs",
  "RGlnaXRhbFBsYXlncm91bmQ=",
  "QmlwaG9yaWE="
)

$AlternateB64 = @(
  "R0VWSQ==",
  "R2F5QWR1bHRFbXBpcmUueW1s",
  "R2F5V2lyZQ==",
  "RmFsY29uU3R1ZGlvcw==",
  "SGVsaXhTdHVkaW9zLnltbA==",
  "Q29ja3lCb3lzLnltbA==",
  "U2VhbkNvZHk=",
  "TmV4dERvb3JTdHVkaW9z",
  "SG90SG91c2U=",
  "S2lua01lbi55bWw=",
  "U3RheHVzLnltbA==",
  "QnJvbW8=",
  "Q2hhb3NNZW4=",
  "QWN0aXZlRHV0eQ==",
  "Q3plY2hIdW50ZXI=",
  "Qm95TmFwcGVk",
  "QmxhY2tNYWxlTWU=",
  "TWVu"
)

$shared = Read-SharedList $ListFile
$listSource = "embedded"
if ($shared.Primary.Count -gt 0 -or $shared.Alternate.Count -gt 0) {
  $PrimaryB64 = $shared.Primary
  $AlternateB64 = $shared.Alternate
  $listSource = "presets/provider-list.b64.txt"
}

$SelectedB64 = @()
switch ($Profile.ToLowerInvariant()) {
  'primary'   { $SelectedB64 = $PrimaryB64 }
  'alternate' { $SelectedB64 = $AlternateB64 }
  default     { $SelectedB64 = $PrimaryB64 + $AlternateB64 }
}

$Selected = $SelectedB64 | ForEach-Object { Decode-Name $_ }

New-Item -ItemType Directory -Path $Dest -Force | Out-Null

$RepoUrl = Decode-Name "aHR0cHM6Ly9naXRodWIuY29tL3N0YXNoYXBwL0NvbW11bml0eVNjcmFwZXJzLmdpdA=="
$ZipUrl  = Decode-Name "aHR0cHM6Ly9naXRodWIuY29tL3N0YXNoYXBwL0NvbW11bml0eVNjcmFwZXJzL2FyY2hpdmUvcmVmcy9oZWFkcy9tYXN0ZXIuemlw"
$PkgDir  = Decode-Name "c2NyYXBlcnM="
$ZipRoot = Decode-Name "Q29tbXVuaXR5U2NyYXBlcnMtbWFzdGVy"

Write-Host "==> providers → $Dest  (Profile=$Profile)" -ForegroundColor Cyan
Write-Host "    源：社区元数据仓库（URL 已编码）" -ForegroundColor DarkGray
Write-Host "    清单：$listSource" -ForegroundColor DarkGray

$haveGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
$srcRoot = $null

if ($haveGit) {
  if (Test-Path (Join-Path $WorkDir ".git")) {
    Write-Host "==> git pull" -ForegroundColor Cyan
    Push-Location $WorkDir
    try {
      git fetch --depth 1 origin master 2>$null | Out-Null
      git checkout -f origin/master 2>$null | Out-Null
    } finally { Pop-Location }
  } else {
    if (Test-Path $WorkDir) { Remove-Item -Recurse -Force $WorkDir }
    Write-Host "==> git clone --depth 1" -ForegroundColor Cyan
    git clone --depth 1 --branch master $RepoUrl $WorkDir
    if ($LASTEXITCODE -ne 0) { throw "git clone 失败" }
  }
  $srcRoot = Join-Path $WorkDir $PkgDir
} else {
  Write-Host "未找到 git，尝试下载 zip…" -ForegroundColor Yellow
  $zip = Join-Path $env:TEMP "mv-community-meta.zip"
  $extract = Join-Path $env:TEMP "mv-community-meta-extract"
  Invoke-WebRequest -Uri $ZipUrl -OutFile $zip
  if (Test-Path $extract) { Remove-Item -Recurse -Force $extract }
  Expand-Archive -Path $zip -DestinationPath $extract -Force
  $srcRoot = Join-Path $extract ($ZipRoot + "\" + $PkgDir)
}

if (-not (Test-Path $srcRoot)) { throw "找不到社区包目录：$srcRoot" }

$ok = 0
$skip = 0
$skipLog = Join-Path $Dest "_skip-log.txt"
$okLog = Join-Path $Dest "_install-log.txt"
$skipLines = @()
$okLines = @()
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

foreach ($name in $Selected) {
  $src = Join-Path $srcRoot $name
  if (-not (Test-Path $src)) {
    Write-Host "  SKIP  (missing upstream)" -ForegroundColor Yellow
    $skip++
    $skipLines += "[$stamp] MISSING profile=$Profile $name"
    continue
  }
  $target = Join-Path $Dest $name
  if (Test-Path $src -PathType Container) {
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Path $src -Destination $target -Recurse -Force
  } else {
    Copy-Item -Path $src -Destination $target -Force
  }
  Write-Host "  OK    $name" -ForegroundColor Green
  $ok++
  $okLines += "[$stamp] OK profile=$Profile $name"
}

$okLines | Set-Content -Path $okLog -Encoding UTF8
$skipLines | Set-Content -Path $skipLog -Encoding UTF8

Write-Host ""
Write-Host "完成：Profile=$Profile，复制 $ok 项，跳过 $skip 项。" -ForegroundColor Cyan
Write-Host "日志：$okLog / $skipLog" -ForegroundColor DarkGray
Write-Host "请到 MediaVault UI 重新加载 providers。" -ForegroundColor Green
Write-Host "（更推荐平时用 UI：Metadata Providers → Community stable）" -ForegroundColor DarkGray
