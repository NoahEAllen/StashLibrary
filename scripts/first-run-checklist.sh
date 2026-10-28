#!/usr/bin/env bash
# 打印首次部署勾选清单（不启动 Docker）。可选 --OpenDocs / -OpenDocs 打开 docs/setup.md。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_DOC="$ROOT/docs/setup.md"
OPEN_DOCS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -OpenDocs|--OpenDocs) OPEN_DOCS=1; shift ;;
    -h|--help) echo "Usage: $0 [--OpenDocs]"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mark() {
  local ok="$1" label="$2"
  if [[ "$ok" == "1" ]]; then
    printf '[x] %s\n' "$label"
  else
    printf '[ ] %s\n' "$label"
  fi
}

exists() { [[ -e "$1" ]] && echo 1 || echo 0; }

echo ""
echo "==== MediaVault 首次部署清单 ===="
echo "根目录: $ROOT"
echo ""

echo "-- 仓库结构 --"
mark "$(exists "$ROOT/scripts/bootstrap.sh")"   "scripts/bootstrap.sh 存在"
mark "$(exists "$ROOT/scripts/bootstrap.ps1")"  "scripts/bootstrap.ps1 存在"
mark "$(exists "$ROOT/docker-compose.yml")"     "docker-compose.yml 存在"
mark "$(exists "$ROOT/.env.example")"           ".env.example 存在"
mark "$(exists "$ROOT/library/primary")"        "library/primary 存在"
mark "$(exists "$ROOT/library/alternate")"      "library/alternate 存在"
mark "$(exists "$ROOT/config/providers")"       "config/providers 存在"
mark "$(exists "$SETUP_DOC")"                   "docs/setup.md 存在"
mark "$(exists "$ROOT/presets/provider-list.b64.txt")" "presets/provider-list.b64.txt 存在"

echo ""
echo "-- 建议操作顺序（勾选自用）--"
echo " 1. ./scripts/bootstrap.sh   （Windows: .\\scripts\\bootstrap.ps1）"
echo " 2. 确认 .env（无则由 start 从 .env.example 生成）"
mark "$(exists "$ROOT/.env")"                   "    当前已有 .env"
echo " 3. ./scripts/start.sh"
echo " 4. 浏览器打开 http://localhost:9999（或 MV_HOST_PORT）"
echo " 5. UI 添加两个库路径："
echo "       Primary   → /data/primary"
echo "       Alternate → /data/alternate"
echo " 6. Settings → 将 Providers Path 指向配置家目录下的 providers"
echo "    （与本仓库 config/providers 对应；键名由 start 解码写入 .env）"
echo " 7. 安装索引包："
echo "       UI Community (stable)  或"
echo "       ./scripts/install-providers.sh -Profile all"
echo "       ./scripts/install-providers.sh -Profile primary"
echo "       ./scripts/install-providers.sh -Profile alternate"
echo " 8. UI 中 Reload providers"
echo " 9. 对两个 Library 执行 Scan（首次 Full Scan）"
echo "10. ./scripts/sanity-check.sh（可选）"
echo "11. 日常：./scripts/update.sh   （可选 -SkipProviders）"

echo ""
echo "跳过日志（安装后）：config/providers/_skip-log.txt（已 gitignore）"
echo ""

if [[ "$OPEN_DOCS" == "1" ]]; then
  if [[ ! -f "$SETUP_DOC" ]]; then
    echo "找不到 docs/setup.md，无法打开。" >&2
    exit 1
  fi
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$SETUP_DOC" >/dev/null 2>&1 || true
    echo "已尝试用 xdg-open 打开 docs/setup.md"
  elif command -v open >/dev/null 2>&1; then
    open "$SETUP_DOC" || true
    echo "已尝试用 open 打开 docs/setup.md"
  else
    echo "请手动打开：$SETUP_DOC"
  fi
fi

echo "==== 清单结束 ===="
echo ""
