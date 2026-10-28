#!/usr/bin/env bash
# 从社区元数据仓库拉取精选 providers 到 config/providers。
# 包名列表来自 presets/provider-list.b64.txt；上游 URL 为 Base64。
# Usage: ./scripts/install-providers.sh [-Profile primary|alternate|all] [--Dest DIR] [--WorkDir DIR]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="all"
DEST="$ROOT/config/providers"
WORKDIR="${TMPDIR:-/tmp}/mv-community-meta"
LIST_FILE="$ROOT/presets/provider-list.b64.txt"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -Profile|--Profile)
      PROFILE="${2:-}"; shift 2 ;;
    -Profile=*)
      PROFILE="${1#*=}"; shift ;;
    --Dest|-Dest)
      DEST="${2:-}"; shift 2 ;;
    --WorkDir|-WorkDir)
      WORKDIR="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [-Profile primary|alternate|all]"
      exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

PROFILE="$(echo "$PROFILE" | tr '[:upper:]' '[:lower:]')"
case "$PROFILE" in
  primary|alternate|all) ;;
  *) echo "Invalid -Profile: $PROFILE (want primary|alternate|all)" >&2; exit 1 ;;
esac

decode_b64() {
  printf '%s' "$1" | base64 -d 2>/dev/null || printf '%s' "$1" | base64 --decode
}

if [[ ! -f "$LIST_FILE" ]]; then
  echo "缺少共享清单：$LIST_FILE" >&2
  exit 1
fi

# Parse shared Base64 list into arrays
PRIMARY=()
ALTERNATE=()
section=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%$'\r'}"
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && {
    if [[ "$line" =~ ---[[:space:]]*primary[[:space:]]*--- ]]; then section="primary"
    elif [[ "$line" =~ ---[[:space:]]*alternate[[:space:]]*--- ]]; then section="alternate"
    fi
    continue
  }
  tok="$(echo "$line" | tr -d '[:space:]')"
  [[ -z "$tok" ]] && continue
  if [[ "$section" == "primary" ]]; then
    PRIMARY+=("$tok")
  elif [[ "$section" == "alternate" ]]; then
    ALTERNATE+=("$tok")
  fi
done < "$LIST_FILE"

SELECTED=()
case "$PROFILE" in
  primary)   SELECTED=("${PRIMARY[@]}") ;;
  alternate) SELECTED=("${ALTERNATE[@]}") ;;
  all)       SELECTED=("${PRIMARY[@]}" "${ALTERNATE[@]}") ;;
esac

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  echo "清单为空或未解析到分组（Profile=$PROFILE）" >&2
  exit 1
fi

mkdir -p "$DEST"

REPO_URL="$(decode_b64 "aHR0cHM6Ly9naXRodWIuY29tL3N0YXNoYXBwL0NvbW11bml0eVNjcmFwZXJzLmdpdA==")"
ZIP_URL="$(decode_b64 "aHR0cHM6Ly9naXRodWIuY29tL3N0YXNoYXBwL0NvbW11bml0eVNjcmFwZXJzL2FyY2hpdmUvcmVmcy9oZWFkcy9tYXN0ZXIuemlw")"
PKG_DIR="$(decode_b64 "c2NyYXBlcnM=")"
ZIP_ROOT="$(decode_b64 "Q29tbXVuaXR5U2NyYXBlcnMtbWFzdGVy")"

echo "==> providers → $DEST  (Profile=$PROFILE)"
echo "    源：社区元数据仓库（URL 已编码）"
echo "    清单：$LIST_FILE"

src_root=""
if command -v git >/dev/null 2>&1; then
  if [[ -d "$WORKDIR/.git" ]]; then
    echo "==> git pull"
    git -C "$WORKDIR" fetch --depth 1 origin master >/dev/null 2>&1 || true
    git -C "$WORKDIR" checkout -f origin/master >/dev/null 2>&1 || true
  else
    rm -rf "$WORKDIR"
    echo "==> git clone --depth 1"
    git clone --depth 1 --branch master "$REPO_URL" "$WORKDIR"
  fi
  src_root="$WORKDIR/$PKG_DIR"
else
  echo "未找到 git，尝试下载 zip…"
  zip="${TMPDIR:-/tmp}/mv-community-meta.zip"
  extract="${TMPDIR:-/tmp}/mv-community-meta-extract"
  rm -rf "$extract"
  mkdir -p "$extract"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$zip" "$ZIP_URL"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$zip" "$ZIP_URL"
  else
    echo "需要 git 或 curl/wget" >&2
    exit 1
  fi
  unzip -q -o "$zip" -d "$extract"
  src_root="$extract/$ZIP_ROOT/$PKG_DIR"
fi

if [[ ! -d "$src_root" && ! -e "$src_root" ]]; then
  echo "找不到社区包目录：$src_root" >&2
  exit 1
fi

ok=0
skip=0
skip_log="$DEST/_skip-log.txt"
ok_log="$DEST/_install-log.txt"
: > "$skip_log"
: > "$ok_log"
stamp="$(date '+%Y-%m-%d %H:%M:%S')"

for b64 in "${SELECTED[@]}"; do
  name="$(decode_b64 "$b64")"
  src="$src_root/$name"
  if [[ ! -e "$src" ]]; then
    echo "  SKIP  (missing upstream)"
    skip=$((skip + 1))
    echo "[$stamp] MISSING profile=$PROFILE $name" >> "$skip_log"
    continue
  fi
  target="$DEST/$name"
  if [[ -d "$src" ]]; then
    rm -rf "$target"
    cp -a "$src" "$target"
  else
    cp -a "$src" "$target"
  fi
  echo "  OK    $name"
  ok=$((ok + 1))
  echo "[$stamp] OK profile=$PROFILE $name" >> "$ok_log"
done

echo ""
echo "完成：Profile=$PROFILE，复制 $ok 项，跳过 $skip 项。"
echo "日志：$ok_log / $skip_log"
echo "请到 MediaVault UI 重新加载 providers。"
echo "（更推荐平时用 UI：Metadata Providers → Community stable）"
