#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "==> MediaVault: docker compose down @ $ROOT"
docker compose down
echo "已停止。"
