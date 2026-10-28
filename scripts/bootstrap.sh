#!/usr/bin/env bash
# 补齐 MediaVault 目录结构。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dirs=(
  "library/primary/asia"
  "library/primary/western"
  "library/primary/indie"
  "library/alternate/studios"
  "library/alternate/western"
  "library/alternate/indie"
  "library/_inbox"
  "config/providers"
  "metadata"
  "cache"
  "blobs"
  "generated"
  "presets"
  "docs"
  "scripts"
)

echo "==> MediaVault bootstrap @ $ROOT"
for d in "${dirs[@]}"; do
  p="$ROOT/$d"
  if [[ ! -d "$p" ]]; then
    mkdir -p "$p"
    echo "  created $d"
  else
    echo "  ok      $d"
  fi
  [[ -f "$p/.gitkeep" ]] || : > "$p/.gitkeep"
done

if [[ ! -f "$ROOT/.env" && -f "$ROOT/.env.example" ]]; then
  echo ""
  echo "提示：可复制 .env.example 为 .env 并修改 MV_HOST_PORT。"
fi

echo ""
echo "下一步："
echo "  ./scripts/start.sh"
echo "  浏览器打开 http://localhost:9999"
echo "  添加库路径 /data/primary 与 /data/alternate （见 presets/libraries.json.example）"
