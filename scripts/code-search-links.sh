#!/usr/bin/env bash
# Print metadata-site search URLs for a catalog code/title/path. Optional --Open (xdg-open/open).
# Usage: ./scripts/code-search-links.sh "ABCD-123" [--Open]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="$ROOT/config/providers-src/asia-catalog/asia_catalog.py"
OPEN=0
QUERY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --Open|-Open) OPEN=1; shift ;;
    -h|--help) echo "Usage: $0 QUERY [--Open]"; exit 0 ;;
    *) QUERY="$1"; shift ;;
  esac
done
[[ -n "$QUERY" ]] || { echo "QUERY required" >&2; exit 1; }
[[ -f "$PY" ]] || { echo "missing $PY" >&2; exit 1; }
if command -v python3 >/dev/null 2>&1; then PYBIN=python3
elif command -v python >/dev/null 2>&1; then PYBIN=python
else echo "python required" >&2; exit 1; fi

OUT=$(QUERY="$QUERY" "$PYBIN" - <<'PY' | "$PYBIN" "$PY" links
import json, os
print(json.dumps({"name": os.environ.get("QUERY", "")}))
PY
)
echo "$OUT" | "$PYBIN" - <<'PY'
import json, sys
data = json.load(sys.stdin)
print("code:", data.get("code"))
for u in data.get("urls") or []:
    print(u)
PY
if [[ "$OPEN" == "1" ]]; then
  echo "$OUT" | "$PYBIN" - <<'PY'
import json, sys, subprocess, shutil
urls = json.load(sys.stdin).get("urls") or []
opener = "xdg-open" if shutil.which("xdg-open") else ("open" if shutil.which("open") else None)
if not opener:
    raise SystemExit(0)
for u in urls:
    subprocess.Popen([opener, u])
PY
fi
