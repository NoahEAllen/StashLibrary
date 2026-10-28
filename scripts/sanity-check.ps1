#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
function Decode-B64([string]$b64) {
  return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
}
$ok = $true
$need = @(
  "library\primary\asia",
  "library\alternate\studios",
  "config\providers",
  "docker-compose.yml",
  "scripts\start.ps1",
  "scripts\install-providers.ps1"
)
Write-Host "==> MediaVault sanity-check" -ForegroundColor Cyan
foreach ($n in $need) {
  $p = Join-Path $Root $n
  if (Test-Path $p) { Write-Host "  ok  $n" } else { Write-Host "  MISS $n" -ForegroundColor Red; $ok = $false }
}
# image token present in start.ps1 as b64
$start = Get-Content (Join-Path $Root "scripts\start.ps1") -Raw
if ($start -match 'Decode-B64 "([A-Za-z0-9+/=]+)"') {
  try {
    $img = Decode-B64 $Matches[1]
    if ($img -match '.+/.+:.+') { Write-Host "  ok  image token decodes" } else { Write-Host "  WARN image decode unexpected: $img" -ForegroundColor Yellow }
  } catch { Write-Host "  FAIL image token" -ForegroundColor Red; $ok = $false }
} else { Write-Host "  FAIL no image token in start.ps1" -ForegroundColor Red; $ok = $false }

# compose should not contain obvious upstream image string
$compose = Get-Content (Join-Path $Root "docker-compose.yml") -Raw
if ($compose -match 'stashapp/') { Write-Host "  FAIL compose still has plaintext image" -ForegroundColor Red; $ok = $false }
else { Write-Host "  ok  compose image via env" }

if ($ok) { Write-Host "`nAll checks passed." -ForegroundColor Green; exit 0 }
else { Write-Host "`nSome checks failed." -ForegroundColor Red; exit 1 }
