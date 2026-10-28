#!/usr/bin/env bash
# 轮询 library/_inbox；发现新媒体文件则调用 auto-scan（默认只扫 /data/_inbox）。
# Usage: ./scripts/watch-inbox.sh [--Interval 60] [--Once]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INBOX="$ROOT/library/_inbox"
INTERVAL=60
ONCE=0
STATE_FILE="$ROOT/cache/_inbox-watch.state"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --Interval|-Interval) INTERVAL="${2:-60}"; shift 2 ;;
    --Once|-Once) ONCE=1; shift ;;
    -h|--help)
      echo "Usage: $0 [--Interval SEC] [--Once]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$(dirname "$STATE_FILE")" "$INBOX"

MEDIA_EXT='mp4|mkv|avi|wmv|mov|m4v|ts|m2ts|webm'

fingerprint() {
  # signature: count + newest mtime + total size (portable-ish)
  find "$INBOX" -type f \( \
      -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' -o -iname '*.wmv' \
      -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.ts' -o -iname '*.m2ts' \
      -o -iname '*.webm' \
    \) -printf '%T@ %s %p\n' 2>/dev/null | sort | sha256sum | awk '{print $1}'
}

LAST=""
if [[ -f "$STATE_FILE" ]]; then
  LAST="$(tr -d '[:space:]' < "$STATE_FILE" || true)"
fi

echo "watch-inbox: $INBOX (interval=${INTERVAL}s)"
while true; do
  CUR="$(fingerprint)"
  if [[ -n "$CUR" && "$CUR" != "$LAST" ]]; then
    echo "$(date '+%F %T') inbox changed -> auto-scan /data/_inbox"
    if "$ROOT/scripts/auto-scan.sh" --Paths "/data/_inbox"; then
      echo "$CUR" > "$STATE_FILE"
      LAST="$CUR"
    else
      echo "auto-scan 失败，下轮重试" >&2
    fi
  else
    echo "$(date '+%F %T') no new media (or empty)"
  fi
  [[ "$ONCE" == "1" ]] && break
  sleep "$INTERVAL"
done
