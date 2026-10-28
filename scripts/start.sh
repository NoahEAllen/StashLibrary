#!/usr/bin/env bash
# 写入 gitignored .env（含解码后的镜像与路径键），然后 docker compose up -d。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

decode_b64() {
  printf '%s' "$1" | base64 -d 2>/dev/null || printf '%s' "$1" | base64 --decode
}

ensure_env_line() {
  local file="$1" key="$2" value="$3"
  [[ -f "$file" ]] || : > "$file"
  if grep -qE "^[[:space:]]*${key}=" "$file" 2>/dev/null; then
    if [[ -n "$value" ]]; then
      # portable in-place without relying on GNU sed -i backup
      local tmp
      tmp="$(mktemp)"
      awk -v k="$key" -v v="$value" '
        BEGIN { done=0 }
        $0 ~ "^[[:space:]]*"k"=" { print k"="v; done=1; next }
        { print }
        END { if (!done) print k"="v }
      ' "$file" > "$tmp"
      mv "$tmp" "$file"
    fi
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

ENV_FILE="$ROOT/.env"
if [[ ! -f "$ENV_FILE" && -f "$ROOT/.env.example" ]]; then
  cp "$ROOT/.env.example" "$ENV_FILE"
fi
[[ -f "$ENV_FILE" ]] || : > "$ENV_FILE"

img=""
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" =~ ^[[:space:]]*MV_IMAGE=(.+)$ ]]; then
    img="${BASH_REMATCH[1]}"
    img="${img%%$'\r'}"
  fi
done < "$ENV_FILE"
if [[ -z "$img" ]]; then
  img="$(decode_b64 "c3Rhc2hhcHAvc3Rhc2g6bGF0ZXN0")"
fi
ensure_env_line "$ENV_FILE" "MV_IMAGE" "$img"
ensure_env_line "$ENV_FILE" "MV_HOST_PORT" "9999"

config_home="$(decode_b64 "L3Jvb3QvLnN0YXNo")"
ensure_env_line "$ENV_FILE" "MV_CONFIG_HOME" "$config_home"
export MV_CONFIG_HOME="$config_home"
export MV_IMAGE="$img"

# Upstream path / port env keys (names encoded)
path_keys=(
  "U1RBU0hfU1RBU0g="
  "U1RBU0hfR0VORVJBVEVE"
  "U1RBU0hfTUVUQURBVEE="
  "U1RBU0hfQ0FDSEU="
  "U1RBU0hfUE9SVA=="
)
path_vals=(
  "L2RhdGEv"
  "L2dlbmVyYXRlZC8="
  "L21ldGFkYXRhLw=="
  "L2NhY2hlLw=="
  "OTk5OQ=="
)
for i in "${!path_keys[@]}"; do
  ensure_env_line "$ENV_FILE" "$(decode_b64 "${path_keys[$i]}")" "$(decode_b64 "${path_vals[$i]}")"
done

echo "==> MediaVault: docker compose up -d @ $ROOT"
docker compose up -d

port="9999"
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" =~ ^[[:space:]]*MV_HOST_PORT=(.+)$ ]]; then
    port="${BASH_REMATCH[1]}"
    port="${port%%$'\r'}"
  fi
done < "$ENV_FILE"

echo ""
echo "服务应已启动：http://localhost:$port"
echo "请添加 Library：/data/primary 与 /data/alternate"
