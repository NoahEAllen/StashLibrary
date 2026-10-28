#!/usr/bin/env bash
# git pull（若是 git 仓）+ docker compose pull + up -d；默认顺带刷新 providers。
# Usage: ./scripts/update.sh [-SkipProviders]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SKIP_PROVIDERS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -SkipProviders|--SkipProviders) SKIP_PROVIDERS=1; shift ;;
    -h|--help)
      echo "Usage: $0 [-SkipProviders]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

echo "==> MediaVault update @ $ROOT"

if [[ -d "$ROOT/.git" ]] && command -v git >/dev/null 2>&1; then
  echo "==> git pull"
  git pull --ff-only || git pull
else
  echo "==> 非 git 仓或无 git，跳过 git pull"
fi

if [[ "$SKIP_PROVIDERS" != "1" ]]; then
  echo "==> install-providers (Profile=all)"
  bash "$ROOT/scripts/install-providers.sh" -Profile all
else
  echo "==> 跳过 providers（-SkipProviders）"
fi

# Ensure .env / secrets via start.sh path (compose up -d)
echo "==> docker compose pull"
# start.sh writes env then up -d; pull first while env may already exist
if [[ -f "$ROOT/.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  # export only simple KEY=VAL lines for compose
  # shellcheck disable=SC1090
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    fi
  done < "$ROOT/.env"
  set +a
fi
docker compose pull || true

echo "==> ensure env + up -d"
bash "$ROOT/scripts/start.sh"

echo ""
echo "更新完成。"
