#!/usr/bin/env bash
# Watch MV_MEDIA_* host roots (and optional inbox); on change call auto-scan without Rescan.
# Usage: ./scripts/watch-media.sh [--Interval 60] [--Once] [--IncludeInbox]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
STATE_FILE="$ROOT/cache/_media-watch.state"
INTERVAL=0
ONCE=0
INCLUDE_INBOX=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --Interval|-Interval) INTERVAL="${2:-60}"; shift 2 ;;
    --Once|-Once) ONCE=1; shift ;;
    --IncludeInbox|-IncludeInbox) INCLUDE_INBOX=1; shift ;;
    -h|--help)
      echo "Usage: $0 [--Interval SEC] [--Once] [--IncludeInbox]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

load_env() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%$'\r'}"
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      local k="${BASH_REMATCH[1]}"
      local v="${BASH_REMATCH[2]}"
      v="${v%\"}"; v="${v#\"}"
      v="${v%\'}"; v="${v#\'}"
      export "$k=$v"
    fi
  done < "$f"
}

load_env "$ENV_FILE"
if [[ "$INTERVAL" -eq 0 ]]; then
  INTERVAL="${MV_WATCH_INTERVAL:-60}"
fi
case "${MV_WATCH_INCLUDE_INBOX:-}" in
  1|true|yes|YES|True) INCLUDE_INBOX=1 ;;
esac

HOSTS=()
CONTAINERS=()
add_pair() {
  local host="$1" cont="$2"
  [[ -z "$host" ]] && return 0
  if [[ ! -d "$host" ]]; then
    echo "warn: skip missing host path: $host" >&2
    return 0
  fi
  HOSTS+=("$host")
  CONTAINERS+=("$cont")
}

add_pair "${MV_MEDIA_TEMP:-}" "/data/primary/sources/temp"
add_pair "${MV_MEDIA_CLOUD:-}" "/data/primary/sources/cloud"
add_pair "${MV_MEDIA_DL:-}" "/data/alternate/sources/downloads"
if [[ "$INCLUDE_INBOX" == "1" ]]; then
  add_pair "$ROOT/library/_inbox" "/data/_inbox"
fi

if [[ ${#HOSTS[@]} -eq 0 ]]; then
  echo "No watch roots. Set MV_MEDIA_TEMP / MV_MEDIA_CLOUD / MV_MEDIA_DL in .env" >&2
  exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"

fingerprint() {
  local i host
  for i in "${!HOSTS[@]}"; do
    host="${HOSTS[$i]}"
    echo "ROOT|${CONTAINERS[$i]}"
    find "$host" -type f \( \
      -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' -o -iname '*.wmv' \
      -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.ts' -o -iname '*.m2ts' \
      -o -iname '*.webm' -o -iname '*.zip' -o -iname '*.rar' -o -iname '*.7z' \
      -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
      -o -iname '*.gif' \
    \) -printf '%T@ %s %p\n' 2>/dev/null
  done | sort | sha256sum | awk '{print $1}'
}

PATHS_ARG="$(IFS=,; echo "${CONTAINERS[*]}")"
LAST=""
if [[ -f "$STATE_FILE" ]]; then
  LAST="$(tr -d '[:space:]' < "$STATE_FILE" || true)"
fi

echo "watch-media: interval=${INTERVAL}s roots=$PATHS_ARG"
while true; do
  CUR="$(fingerprint)"
  if [[ -n "$CUR" && "$CUR" != "$LAST" ]]; then
    echo "$(date '+%F %T') media roots changed -> auto-scan $PATHS_ARG"
    if "$ROOT/scripts/auto-scan.sh" --Paths "$PATHS_ARG"; then
      echo "$CUR" > "$STATE_FILE"
      LAST="$CUR"
    else
      echo "auto-scan failed; will retry" >&2
    fi
  else
    echo "$(date '+%F %T') no change"
  fi
  [[ "$ONCE" == "1" ]] && break
  sleep "$INTERVAL"
done

