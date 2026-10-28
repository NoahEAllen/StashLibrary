#!/usr/bin/env bash
# 将 config/providers-src/* 复制到 config/providers/（本地自定义 provider）。
# Usage: ./scripts/install-local-providers.sh [--Dest DIR]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/config/providers-src"
DEST="$ROOT/config/providers"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --Dest|-Dest) DEST="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--Dest DIR]"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -d "$SRC" ]]; then
  echo "缺少本地源目录: $SRC" >&2
  exit 1
fi

mkdir -p "$DEST"
count=0
shopt -s nullglob
for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  [[ "$name" == .* ]] && continue
  target="$DEST/$name"
  mkdir -p "$target"
  # copy files (overwrite)
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude '.gitkeep' "$dir" "$target/"
  else
    rm -rf "$target"
    mkdir -p "$target"
    cp -a "$dir"/. "$target"/
  fi
  echo "installed local provider: $name -> $target"
  count=$((count + 1))
done
shopt -u nullglob

if [[ "$count" -eq 0 ]]; then
  echo "providers-src 下没有可安装的子目录" >&2
  exit 1
fi
echo "done: $count local provider package(s). Reload providers in UI."
