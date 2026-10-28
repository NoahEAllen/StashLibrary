#Requires -Version 5.1
<#
.SYNOPSIS
  结构完整性 + 明文敏感词扫描（脚本内 Base64 载荷允许）。
#>
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
$failed = 0

function Fail([string]$msg) {
  Write-Host "FAIL  $msg" -ForegroundColor Red
  $script:failed++
}
function Ok([string]$msg) {
  Write-Host "OK    $msg" -ForegroundColor Green
}
function Decode-B64([string]$b64) {
  return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
}

Write-Host "==> MediaVault sanity-check @ $Root" -ForegroundColor Cyan

# --- required paths ---
$required = @(
  "docker-compose.yml",
  ".env.example",
  ".gitignore",
  "README.md",
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
  "docs\setup.md",
  "docs\naming.md",
  "docs\providers.md",
  "docs\git-publish.md",
  "docs\architecture.md",
  "presets\libraries.json.example",
  "presets\recommended-settings.md",
  "presets\provider-list.b64.txt",
  "scripts\bootstrap.ps1",
  "scripts\start.ps1",
  "scripts\stop.ps1",
  "scripts\install-providers.ps1",
  "scripts\first-run-checklist.ps1",
  "scripts\sanity-check.ps1",
  "scripts\export-provider-list.ps1",
  "scripts\update.ps1",
  "scripts\bootstrap.sh",
  "scripts\start.sh",
  "scripts\stop.sh",
  "scripts\install-providers.sh",
  "scripts\first-run-checklist.sh",
  "scripts\sanity-check.sh",
  "scripts\update.sh",
  "scripts\install-local-providers.ps1",
  "scripts\install-local-providers.sh",
  "scripts\auto-scan.ps1",
  "scripts\auto-scan.sh",
  "scripts\watch-inbox.ps1",
  "scripts\watch-inbox.sh",
  "config\providers-src\asia-catalog\asia-catalog.yml",
  "config\providers-src\asia-catalog\asia_catalog.py",
  "config\providers-src\asia-catalog\README.md"
)
foreach ($r in $required) {
  $p = Join-Path $Root $r
  if (Test-Path $p) { Ok "exists $r" } else { Fail "missing $r" }
}

# --- compose uses variables, not plaintext image ---
$compose = Get-Content (Join-Path $Root "docker-compose.yml") -Raw
if ($compose -match '\$\{MV_IMAGE\}') { Ok "compose image uses MV_IMAGE" } else { Fail "compose missing MV_IMAGE var" }
if ($compose -match '\$\{MV_CONFIG_HOME\}') { Ok "compose config mount uses MV_CONFIG_HOME" } else { Fail "compose missing MV_CONFIG_HOME var" }
if ($compose -match 'container_name:\s*mediavault') { Ok "container_name=mediavault" } else { Fail "bad container_name" }
if ($compose -match 'image:\s*\$\{MV_IMAGE\}') { Ok "no plaintext image name in compose" } else { Fail "compose image line unexpected" }

# --- .gitignore covers secrets ---
$gi = Get-Content (Join-Path $Root ".gitignore") -Raw
foreach ($pat in @('.env', 'config/providers', 'metadata', '*.mp4', '_skip-log.txt')) {
  if ($gi -match [regex]::Escape($pat)) { Ok "gitignore has $pat" } else { Fail "gitignore missing $pat" }
}

# --- forbidden plaintext scan (words stored as Base64) ---
$ForbiddenB64 = @(
  "c3Rhc2g=",
  "cG9ybg==",
  "amF2",
  "Z2F5",
  "aG9tbw==",
  "c3RyYWlnaHQ=",
  "YWR1bHQ=",
  "eHh4",
  "c2NyYXBlcg==",
  "cGVhY2g=",
  "55Wq5Y+3"
)
$Forbidden = $ForbiddenB64 | ForEach-Object { Decode-B64 $_ }

$includeExt = @('.md', '.yml', '.yaml', '.ps1', '.sh', '.example', '.json', '.txt', '.gitignore')
$excludeName = @('_skip-log.txt', '_install-log.txt', 'provider-list.b64.txt', '_OUT.txt')

$files = Get-ChildItem -Path $Root -Recurse -File | Where-Object {
  $ext = $_.Extension.ToLowerInvariant()
  ($ext -in $includeExt -or $_.Name -eq '.gitignore' -or $_.Name -like '.env*') -and
  ($_.Name -notin $excludeName) -and
  ($_.FullName -notmatch '[\\/]config[\\/]providers[\\/].+') -and
  ($_.FullName -notmatch '[\\/]\.git[\\/]')
}

foreach ($f in $files) {
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/')
  $nameLower = $f.Name.ToLowerInvariant()
  foreach ($word in $Forbidden) {
    $w = $word.ToLowerInvariant()
    if ($nameLower -match ("(^|[^a-z0-9])" + [regex]::Escape($w) + "([^a-z0-9]|$)")) {
      Fail "sensitive token in filename $rel"
    }
  }
  $lines = Get-Content $f.FullName -ErrorAction SilentlyContinue
  $lineNo = 0
  foreach ($line in $lines) {
    $lineNo++
    $scrub = [regex]::Replace($line, '[A-Za-z0-9+/]{8,}={0,2}', 'B64')
    $lower = $scrub.ToLowerInvariant()
    foreach ($word in $Forbidden) {
      $w = $word.ToLowerInvariant()
      if ($lower -match ("(^|[^a-z0-9])" + [regex]::Escape($w) + "([^a-z0-9]|$)")) {
        Fail "sensitive token in $rel`:$lineNo"
      }
      elseif ($scrub -like "*$word*" -and $word -match '[\u4e00-\u9fff]') {
        Fail "sensitive CJK in $rel`:$lineNo"
      }
    }
  }
}

# --- start scripts encoded blobs ---
foreach ($name in @('start.ps1', 'start.sh')) {
  $start = Get-Content (Join-Path $Root "scripts\$name") -Raw
  if ($start -match 'c3Rhc2hhcHAvc3Rhc2g6bGF0ZXN0') { Ok "$name has encoded image" } else { Fail "$name missing encoded image blob" }
  if ($start -match 'L3Jvb3QvLnN0YXNo') { Ok "$name has encoded config home" } else { Fail "$name missing encoded config home" }
}

# --- install-providers: Profile + shared list ---
foreach ($name in @('install-providers.ps1', 'install-providers.sh')) {
  $inst = Get-Content (Join-Path $Root "scripts\$name") -Raw
  if ($inst -match 'provider-list\.b64\.txt') { Ok "$name references shared list" } else { Fail "$name missing shared list ref" }
  if ($inst -match '\$Profile' -or $inst -match 'PROFILE') {
    if ($inst -match "primary" -and $inst -match "alternate" -and $inst -match "all") {
      Ok "$name has Profile primary|alternate|all"
    } else { Fail "$name missing Profile values" }
  } else { Fail "$name missing Profile" }
  if ($inst -match '_skip-log\.txt') { Ok "$name skip-log under providers" } else { Fail "$name missing skip-log path" }
  if ($inst -match 'Q29tbXVuaXR5U2NyYXBlcnM') { Ok "$name has encoded community marker" } else { Fail "$name missing community encoding" }
}

# count encoded package entries in shared list
$listRaw = Get-Content (Join-Path $Root "presets\provider-list.b64.txt")
$cnt = @($listRaw | Where-Object { $_ -match '^[A-Za-z0-9+/=]{8,}$' }).Count
if ($cnt -ge 30) { Ok "provider-list.b64.txt has $cnt entries" } else { Fail "provider-list.b64.txt too few ($cnt)" }

# --- update scripts ---
foreach ($name in @('update.ps1', 'update.sh')) {
  $upd = Get-Content (Join-Path $Root "scripts\$name") -Raw
  if ($upd -match 'git pull') { Ok "$name has git pull" } else { Fail "$name missing git pull" }
  if ($upd -match 'compose pull') { Ok "$name has compose pull" } else { Fail "$name missing compose pull" }
  if ($upd -match 'SkipProviders') { Ok "$name has SkipProviders" } else { Fail "$name missing SkipProviders" }
}

# --- first-run-checklist markers ---
foreach ($name in @('first-run-checklist.ps1', 'first-run-checklist.sh')) {
  $chk = Get-Content (Join-Path $Root "scripts\$name") -Raw
  if ($chk -match 'OpenDocs') { Ok "$name has OpenDocs" } else { Fail "$name missing OpenDocs" }
  if ($chk -match '/data/primary' -and $chk -match '/data/alternate') { Ok "$name mentions both library paths" } else { Fail "$name missing library paths" }
  if ($chk -match 'Reload' -or $chk -match 'Scan') { Ok "$name mentions Reload/Scan" } else { Fail "$name missing Reload/Scan" }
}

# --- README daily update + platforms ---
$readme = Get-Content (Join-Path $Root "README.md") -Raw
if ($readme -match '日常更新' -and $readme -match 'git pull' -and $readme -match 'install-providers' -and $readme -match 'compose pull') {
  Ok "README has daily update block"
} else {
  Fail "README missing daily update (pull / install-providers / compose pull)"
}
if (($readme -match 'Windows' -or $readme -match '\.ps1') -and ($readme -match 'Linux' -or $readme -match 'macOS' -or $readme -match '\.sh')) {
  Ok "README mentions Windows ps1 + Linux/macOS sh"
} else {
  Fail "README missing platform script notes"
}


# --- local providers + auto-scan ---
foreach ($name in @('install-local-providers.ps1', 'install-local-providers.sh')) {
  $raw = Get-Content (Join-Path $Root "scripts\$name") -Raw
  if ($raw -match 'providers-src') { Ok "$name copies providers-src" } else { Fail "$name missing providers-src copy logic" }
}
foreach ($name in @('auto-scan.ps1', 'auto-scan.sh')) {
  $raw = Get-Content (Join-Path $Root "scripts\$name") -Raw
  if ($raw -match 'metadataScan') { Ok "$name uses metadataScan" } else { Fail "$name missing metadataScan" }
  if ($raw -match 'MV_API_KEY') { Ok "$name reads MV_API_KEY" } else { Fail "$name missing MV_API_KEY" }
  if ($raw -match 'ApiKey') { Ok "$name sends ApiKey header" } else { Fail "$name missing ApiKey header" }
}
foreach ($name in @('watch-inbox.ps1', 'watch-inbox.sh')) {
  $raw = Get-Content (Join-Path $Root "scripts\$name") -Raw
  if ($raw -match '_inbox') { Ok "$name watches _inbox" } else { Fail "$name missing _inbox" }
  if ($raw -match 'auto-scan') { Ok "$name calls auto-scan" } else { Fail "$name missing auto-scan call" }
}

$arch = Get-Content (Join-Path $Root "docs\architecture.md") -Raw
if ($arch -match 'compose pull' -and ($arch -match 'vendoring' -or $arch -match 'upstream')) {
  Ok "architecture explains no-vendoring + compose pull"
} else { Fail "architecture missing upgrade/vendoring notes" }
if ($arch -match 'asia-catalog') { Ok "architecture mentions asia-catalog" } else { Fail "architecture missing asia-catalog" }
if ($arch -match 'metadataScan' -or $arch -match 'GraphQL' -or $arch -match 'auto-scan') {
  Ok "architecture mentions auto-scan/GraphQL"
} else { Fail "architecture missing auto-scan" }

$envex = Get-Content (Join-Path $Root ".env.example") -Raw
if ($envex -match 'MV_API_KEY') { Ok ".env.example mentions MV_API_KEY" } else { Fail ".env.example missing MV_API_KEY" }

$yml = Get-Content (Join-Path $Root "config\providers-src\asia-catalog\asia-catalog.yml") -Raw
if ($yml -match 'action:\s*script' -and $yml -match 'asia_catalog\.py') {
  Ok "asia-catalog.yml is script provider"
} else { Fail "asia-catalog.yml unexpected" }

# --- setup.md ---
$setup = Get-Content (Join-Path $Root "docs\setup.md") -Raw
if ($setup -match '-Profile' -and $setup -match 'first-run-checklist') {
  Ok "setup.md documents Profile + checklist"
} else {
  Fail "setup.md missing Profile or checklist"
}
if ($setup -match '\.ps1' -and $setup -match '\.sh') {
  Ok "setup.md documents ps1 + sh"
} else {
  Fail "setup.md missing ps1/sh notes"
}
if ($setup -match 'MV_API_KEY' -and $setup -match 'auto-scan') {
  Ok "setup.md documents API Key + auto-scan"
} else { Fail "setup.md missing auto-scan section" }
if ($setup -match 'cron' -or $setup -match 'Task Scheduler' -or $setup -match 'schtasks') {
  Ok "setup.md has scheduler example"
} else { Fail "setup.md missing cron/task example" }
if ($setup -match 'install-local-providers') {
  Ok "setup.md documents local providers"
$setupAlbums = Get-Content (Join-Path $Root "docs\setup.md") -Raw -ErrorAction SilentlyContinue
if ($setupAlbums -match 'albums' -and $setupAlbums -match 'Images') { Ok "setup.md documents albums + Images scan" } else { Fail "setup.md missing albums/Images scan notes" }
$namingAlbums = Get-Content (Join-Path $Root "docs\naming.md") -Raw -ErrorAction SilentlyContinue
if ($namingAlbums -match 'albums') { Ok "naming.md documents albums" } else { Fail "naming.md missing albums" }
} else { Fail "setup.md missing local providers" }

Write-Host ""
if ($failed -gt 0) {
  Write-Host "sanity-check FAILED: $failed issue(s)" -ForegroundColor Red
  exit 1
} else {
  Write-Host "sanity-check PASSED" -ForegroundColor Green
  exit 0
}
