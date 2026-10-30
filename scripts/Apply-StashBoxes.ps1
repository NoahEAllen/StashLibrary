# Apply / merge Stash-Box endpoints. Preserves existing keys when env vars omitted.
# Usage (PowerShell):
#   $env:STASHDB_API_KEY = "<stashdb>"
#   $env:TPDB_API_KEY = "<theporndb>"          # optional
#   $env:PMV_API_KEY = "<pmvstash>"            # optional
#   $env:FANSDB_API_KEY = "<fansdb>"           # optional
#   powershell -NoProfile -ExecutionPolicy Bypass -File E:\stashLibrary\scripts\Apply-StashBoxes.ps1
#
# Merge rules:
# - Starts from current Stash config stashBoxes (so a partial env update won't wipe others).
# - Env keys override matching endpoint entries.
# - Never invents keys. Leaves scrapers alone. Does not start Identify.
# - Excludes JAVStash unless you explicitly set $env:JAVSTASH_API_KEY (not default).

$ErrorActionPreference = "Stop"
$gqlUrl = "http://127.0.0.1:9999/graphql"

function Invoke-StashGql($query, $variables) {
  $payload = @{ query = $query }
  if ($null -ne $variables) { $payload.variables = $variables }
  $json = $payload | ConvertTo-Json -Depth 12 -Compress
  $tmp = Join-Path $env:TEMP ("stashbox-" + [guid]::NewGuid().ToString() + ".json")
  [System.IO.File]::WriteAllText($tmp, $json, [System.Text.UTF8Encoding]::new($false))
  try {
    $resp = Invoke-WebRequest -Uri $gqlUrl -Method Post -ContentType "application/json; charset=utf-8" -InFile $tmp -UseBasicParsing
    return ($resp.Content | ConvertFrom-Json)
  } finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  }
}

function Get-Rpm($endpoint, $existingRpm) {
  if ($null -ne $existingRpm -and [int]$existingRpm -gt 0) { return [int]$existingRpm }
  $ep = [string]$endpoint
  if ($ep -match 'stashdb\.org') { return 240 }
  if ($ep -match 'theporndb|pmvstash|fansdb') { return 60 }
  return 240
}

function Normalize-Endpoint([string]$ep) {
  if ($ep -match 'theporndb\.net') { return "https://api.theporndb.net/graphql" }
  return $ep.TrimEnd('/')
}

$catalog = @(
  @{ name = "StashDB";    endpoint = "https://stashdb.org/graphql";      env = "STASHDB_API_KEY";  rpm = 240 },
  @{ name = "ThePornDB";  endpoint = "https://api.theporndb.net/graphql"; env = "TPDB_API_KEY";     rpm = 60 },
  @{ name = "PMV Stash";  endpoint = "https://pmvstash.org/graphql";     env = "PMV_API_KEY";      rpm = 60 },
  @{ name = "FansDB";     endpoint = "https://fansdb.cc/graphql";        env = "FANSDB_API_KEY";   rpm = 60 }
)

# 1) Read current
$readQ = @'
query {
  configuration {
    general {
      stashBoxes { name endpoint api_key max_requests_per_minute }
    }
  }
}
'@
$cur = Invoke-StashGql $readQ $null
if ($cur.errors) {
  Write-Host "READ ERROR:"
  $cur.errors | ConvertTo-Json -Depth 5
  exit 1
}

$existing = @($cur.data.configuration.general.stashBoxes)
$byEp = @{}
foreach ($b in $existing) {
  $ep = Normalize-Endpoint ([string]$b.endpoint)
  # skip javstash unless env provided later
  if ($ep -match 'javstash' -and -not ($env:JAVSTASH_API_KEY)) { continue }
  $byEp[$ep] = @{
    name = [string]$b.name
    endpoint = $ep
    api_key = [string]$b.api_key
    max_requests_per_minute = (Get-Rpm $ep $b.max_requests_per_minute)
  }
}

# 2) Overlay env catalog
foreach ($c in $catalog) {
  $key = [Environment]::GetEnvironmentVariable($c.env)
  if (-not $key -or $key.Trim().Length -eq 0) { continue }
  $ep = Normalize-Endpoint $c.endpoint
  $byEp[$ep] = @{
    name = $c.name
    endpoint = $c.endpoint
    api_key = $key.Trim()
    max_requests_per_minute = [int]$c.rpm
  }
}

# Optional JAVStash only if env set
if ($env:JAVSTASH_API_KEY -and $env:JAVSTASH_API_KEY.Trim().Length -gt 0) {
  $byEp["https://javstash.org/graphql"] = @{
    name = "JAVStash"
    endpoint = "https://javstash.org/graphql"
    api_key = $env:JAVSTASH_API_KEY.Trim()
    max_requests_per_minute = 60
  }
}

# Preferred order
$order = @(
  "https://stashdb.org/graphql",
  "https://api.theporndb.net/graphql",
  "https://pmvstash.org/graphql",
  "https://fansdb.cc/graphql",
  "https://javstash.org/graphql"
)

$boxes = @()
$seen = @{}
foreach ($ep in $order) {
  if ($byEp.ContainsKey($ep)) {
    $boxes += $byEp[$ep]
    $seen[$ep] = $true
  }
}
foreach ($k in $byEp.Keys) {
  if (-not $seen.ContainsKey($k)) { $boxes += $byEp[$k] }
}

if ($boxes.Count -eq 0) {
  Write-Host "No stash-box keys found (env empty and config empty)."
  Write-Host "Set STASHDB_API_KEY / TPDB_API_KEY / PMV_API_KEY as needed."
  exit 2
}

$mut = @'
mutation ($input: ConfigGeneralInput!) {
  configureGeneral(input: $input) {
    stashBoxes { name endpoint api_key max_requests_per_minute }
  }
}
'@

$vars = @{ input = @{ stashBoxes = $boxes } }
$r = Invoke-StashGql $mut $vars
if ($r.errors) {
  Write-Host "ERROR:"
  $r.errors | ConvertTo-Json -Depth 5
  exit 1
}

Write-Host "Configured stashBoxes:"
foreach ($b in $r.data.configureGeneral.stashBoxes) {
  $k = if ($b.api_key) { "SET len=$($b.api_key.Length)" } else { "EMPTY" }
  $rpm = $b.max_requests_per_minute
  Write-Host ("  {0} | {1} | rpm={2} | {3}" -f $b.name, $b.endpoint, $rpm, $k)
}

Write-Host "Done. Next: UI Scene Tagger / Identify (small batch). Avoid full-library Identify while Sense FP runs."
Write-Host "Note: GraphQL may report rpm=0 even when config.yml has the real maxrequestsperminute; check config.yml if unsure."

