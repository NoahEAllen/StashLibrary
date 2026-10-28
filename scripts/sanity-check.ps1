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
  "scripts\bootstrap.ps1",
  "scripts\start.ps1",
  "scripts\stop.ps1",
  "scripts\install-providers.ps1",
  "scripts\first-run-checklist.ps1",
  "scripts\sanity-check.ps1",
  "scripts\export-provider-list.ps1"
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

$includeExt = @('.md', '.yml', '.yaml', '.ps1', '.example', '.json', '.txt', '.gitignore')
$excludeName = @('_skip-log.txt', '_install-log.txt', 'provider-list.b64.txt')

$files = Get-ChildItem -Path $Root -Recurse -File | Where-Object {
  $ext = $_.Extension.ToLowerInvariant()
  ($ext -in $includeExt -or $_.Name -eq '.gitignore' -or $_.Name -like '.env*') -and
  ($_.Name -notin $excludeName) -and
  ($_.FullName -notmatch '[\\/]config[\\/]providers[\\/].+') -and
  ($_.FullName -notmatch '[\\/]\.git[\\/]')
}

foreach ($f in $files) {
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/')
  # Filenames must also be clean
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
    # Strip base64-looking tokens before scanning
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

# --- start.ps1 must contain encoded blobs ---
$start = Get-Content (Join-Path $Root "scripts\start.ps1") -Raw
if ($start -match 'c3Rhc2hhcHAvc3Rhc2g6bGF0ZXN0') { Ok "start.ps1 has encoded image" } else { Fail "start.ps1 missing encoded image blob" }
if ($start -match 'L3Jvb3QvLnN0YXNo') { Ok "start.ps1 has encoded config home" } else { Fail "start.ps1 missing encoded config home" }

# --- install-providers: Profile + split arrays ---
$inst = Get-Content (Join-Path $Root "scripts\install-providers.ps1") -Raw
if ($inst -match 'PrimaryB64') { Ok "install-providers has PrimaryB64" } else { Fail "install-providers missing PrimaryB64" }
if ($inst -match 'AlternateB64') { Ok "install-providers has AlternateB64" } else { Fail "install-providers missing AlternateB64" }
if ($inst -match 'ValidateSet\(''primary'')' -or $inst -match 'ValidateSet\("primary"\)' -or $inst -match "ValidateSet\('primary'") {
  Ok "install-providers has ValidateSet Profile"
} elseif ($inst -match '\$Profile' -and $inst -match "primary" -and $inst -match "alternate" -and $inst -match "all") {
  Ok "install-providers has Profile primary|alternate|all"
} else {
  Fail "install-providers missing Profile param"
}
if ($inst -match 'config\\providers' -or $inst -match '_skip-log\.txt') {
  Ok "install-providers skip-log under providers"
} else {
  Fail "install-providers missing skip-log path"
}
if ($inst -match 'Q29tbXVuaXR5U2NyYXBlcnM') { Ok "install-providers has encoded community marker" } else { Fail "install-providers missing community encoding" }

# count encoded package entries across both arrays
$cnt = ([regex]::Matches($inst, '"([A-Za-z0-9+/=]{8,})"')).Count
if ($cnt -ge 30) { Ok "install-providers has many encoded entries ($cnt quotes)" } else { Fail "install-providers too few encoded strings ($cnt)" }

# --- first-run-checklist markers ---
$chk = Get-Content (Join-Path $Root "scripts\first-run-checklist.ps1") -Raw
if ($chk -match 'OpenDocs') { Ok "first-run-checklist has -OpenDocs" } else { Fail "first-run-checklist missing OpenDocs" }
if ($chk -match '/data/primary' -and $chk -match '/data/alternate') { Ok "first-run-checklist mentions both library paths" } else { Fail "first-run-checklist missing library paths" }
if ($chk -match 'Reload' -or $chk -match 'Scan') { Ok "first-run-checklist mentions Reload/Scan" } else { Fail "first-run-checklist missing Reload/Scan" }

# --- README daily update ---
$readme = Get-Content (Join-Path $Root "README.md") -Raw
if ($readme -match '日常更新' -and $readme -match 'git pull' -and $readme -match 'install-providers' -and $readme -match 'compose pull') {
  Ok "README has daily update block"
} else {
  Fail "README missing daily update (pull / install-providers / compose pull)"
}

# --- setup.md Profile docs ---
$setup = Get-Content (Join-Path $Root "docs\setup.md") -Raw
if ($setup -match '-Profile' -and $setup -match 'first-run-checklist') {
  Ok "setup.md documents Profile + checklist"
} else {
  Fail "setup.md missing Profile or checklist"
}

Write-Host ""
if ($failed -gt 0) {
  Write-Host "sanity-check FAILED: $failed issue(s)" -ForegroundColor Red
  exit 1
} else {
  Write-Host "sanity-check PASSED" -ForegroundColor Green
  exit 0
}
