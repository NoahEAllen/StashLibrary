#Requires -Version 5.1
<#
.SYNOPSIS
  通过编目服务 GraphQL API 触发 metadataScan。
  读取 .env 的 MV_API_KEY；可选 MV_GRAPHQL_URL。
#>
param(
  [string]$Paths = "",
  [switch]$Rescan,
  [string]$Url = ""
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $Root ".env"

function Get-DotEnv([string]$path) {
  $map = @{}
  if (-not (Test-Path $path)) { return $map }
  Get-Content $path | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    $i = $line.IndexOf("=")
    if ($i -lt 1) { return }
    $k = $line.Substring(0, $i).Trim()
    $v = $line.Substring($i + 1).Trim().Trim('"').Trim("'")
    $map[$k] = $v
  }
  return $map
}

$envMap = Get-DotEnv $EnvFile
$apiKey = $envMap["MV_API_KEY"]
if (-not $apiKey) { $apiKey = $env:MV_API_KEY }
if (-not $apiKey) {
  Write-Error "缺少 API Key：请在 UI 生成后写入 .env 的 MV_API_KEY"
  exit 1
}

$graphql = $Url
if (-not $graphql) { $graphql = $envMap["MV_GRAPHQL_URL"] }
if (-not $graphql) {
  $port = $envMap["MV_HOST_PORT"]
  if (-not $port) { $port = "9999" }
  $graphql = "http://localhost:$port/graphql"
}

$inputObj = @{}
if ($Paths) {
  $inputObj["paths"] = @($Paths.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
if ($Rescan) { $inputObj["rescan"] = $true }

$bodyObj = @{
  query = "mutation MetadataScan(`$input: ScanMetadataInput!) { metadataScan(input: `$input) }"
  variables = @{ input = $inputObj }
}
$json = $bodyObj | ConvertTo-Json -Depth 6 -Compress

Write-Host "POST $graphql  (paths=$(if ($Paths) { $Paths } else { '<all>' }) rescan=$([bool]$Rescan))"
try {
  $resp = Invoke-RestMethod -Method Post -Uri $graphql -ContentType "application/json" `
    -Headers @{ ApiKey = $apiKey } -Body $json
} catch {
  Write-Error "请求失败：编目服务是否已启动？ $_"
  exit 1
}

$raw = $resp | ConvertTo-Json -Depth 8
Write-Host $raw
if ($resp.errors) {
  Write-Error "GraphQL errors"
  exit 1
}
if (-not $resp.data.metadataScan) {
  Write-Error "响应中未见 metadataScan job id"
  exit 1
}
Write-Host "Scan job submitted: $($resp.data.metadataScan)"
