#!/usr/bin/env bash
# 通过编目服务 GraphQL API 触发 metadataScan。
# 读取 .env 中 MV_API_KEY；可选 MV_GRAPHQL_URL（默认 http://localhost:9999/graphql）。
# Usage: ./scripts/auto-scan.sh [--Paths /data/primary,/data/alternate] [--Rescan]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
GRAPHQL_URL=""
API_KEY=""
PATHS=""
RESCAN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --Paths|-Paths) PATHS="${2:-}"; shift 2 ;;
    --Rescan|-Rescan) RESCAN=1; shift ;;
    --Url|-Url) GRAPHQL_URL="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--Paths p1,p2] [--Rescan] [--Url URL]"
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
API_KEY="${MV_API_KEY:-${API_KEY:-}}"
GRAPHQL_URL="${GRAPHQL_URL:-${MV_GRAPHQL_URL:-http://localhost:9999/graphql}}"
PORT="${MV_HOST_PORT:-9999}"
if [[ "$GRAPHQL_URL" == "http://localhost:9999/graphql" && "$PORT" != "9999" ]]; then
  GRAPHQL_URL="http://localhost:${PORT}/graphql"
fi

if [[ -z "$API_KEY" ]]; then
  echo "缺少 API Key：请在 UI 生成后写入 .env 的 MV_API_KEY" >&2
  exit 1
fi

# Build GraphQL JSON with python for safe escaping
PAYLOAD="$(PATHS_ARG="$PATHS" RESCAN_ARG="$RESCAN" python3 - <<'PY'
import json, os
paths_raw = os.environ.get("PATHS_ARG", "").strip()
rescan = os.environ.get("RESCAN_ARG", "0") == "1"
inp = {}
if paths_raw:
    inp["paths"] = [p.strip() for p in paths_raw.split(",") if p.strip()]
if rescan:
    inp["rescan"] = True
query = "mutation MetadataScan($input: ScanMetadataInput!) { metadataScan(input: $input) }"
print(json.dumps({"query": query, "variables": {"input": inp}}))
PY
)"

echo "POST $GRAPHQL_URL  (paths=${PATHS:-<all>} rescan=$RESCAN)"
HTTP_CODE=0
RESP="$(curl -sS -w '\n%{http_code}' -X POST "$GRAPHQL_URL" \
  -H "Content-Type: application/json" \
  -H "ApiKey: $API_KEY" \
  -d "$PAYLOAD")" || {
  echo "curl 失败：编目服务是否已启动？" >&2
  exit 1
}
HTTP_CODE="$(echo "$RESP" | tail -n1)"
BODY="$(echo "$RESP" | sed '$d')"
echo "HTTP $HTTP_CODE"
echo "$BODY"
echo "$BODY" | grep -q '"errors"' && exit 1 || true
echo "$BODY" | grep -Eq 'metadataScan' || {
  echo "响应中未见 metadataScan job id" >&2
  exit 1
}
echo "Scan job submitted."
