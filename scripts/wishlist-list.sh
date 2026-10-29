#!/usr/bin/env bash
# List wish-list rows by status (default pending).
# Usage: ./scripts/wishlist-list.sh [--Csv path] [--Status pending]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSV=""
STATUS="pending"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --Csv|-Csv) CSV="${2:-}"; shift 2 ;;
    --Status|-Status) STATUS="${2:-pending}"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--Csv path] [--Status pending]"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done
if [[ -z "$CSV" ]]; then
  if [[ -f "$ROOT/cache/performer-wishlist.csv" ]]; then
    CSV="$ROOT/cache/performer-wishlist.csv"
  else
    CSV="$ROOT/presets/performer-wishlist.csv.example"
  fi
fi
[[ -f "$CSV" ]] || { echo "CSV not found: $CSV" >&2; exit 1; }
echo "file: $CSV  status=$STATUS"
python3 - "$CSV" "$STATUS" <<'PY'
import csv, sys
path, status = sys.argv[1], sys.argv[2]
with open(path, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))
matched = [r for r in rows if (r.get("status") or "").strip() == status]
print(f"count: {len(matched)}")
for r in matched:
    print(f"{r.get('performer','')}\t{r.get('title_or_code','')}\t{r.get('notes','')}")
PY
