#!/usr/bin/env bash
# 结构完整性 + 明文敏感词扫描（脚本内 Base64 载荷允许）。
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0

fail() { echo "FAIL  $1"; failed=$((failed + 1)); }
ok()   { echo "OK    $1"; }

decode_b64() {
  printf '%s' "$1" | base64 -d 2>/dev/null || printf '%s' "$1" | base64 --decode
}

echo "==> MediaVault sanity-check @ $ROOT"

required=(
  "docker-compose.yml"
  ".env.example"
  ".gitignore"
  "README.md"
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
  "docs/setup.md"
  "docs/naming.md"
  "docs/providers.md"
  "docs/git-publish.md"
  "docs/architecture.md"
  "presets/libraries.json.example"
  "presets/recommended-settings.md"
  "presets/provider-list.b64.txt"
  "scripts/bootstrap.ps1"
  "scripts/start.ps1"
  "scripts/stop.ps1"
  "scripts/install-providers.ps1"
  "scripts/first-run-checklist.ps1"
  "scripts/sanity-check.ps1"
  "scripts/export-provider-list.ps1"
  "scripts/update.ps1"
  "scripts/bootstrap.sh"
  "scripts/start.sh"
  "scripts/stop.sh"
  "scripts/install-providers.sh"
  "scripts/first-run-checklist.sh"
  "scripts/sanity-check.sh"
  "scripts/update.sh"
)

for r in "${required[@]}"; do
  if [[ -e "$ROOT/$r" ]]; then ok "exists $r"; else fail "missing $r"; fi
done

compose="$(cat "$ROOT/docker-compose.yml")"
[[ "$compose" == *'${MV_IMAGE}'* ]] && ok "compose image uses MV_IMAGE" || fail "compose missing MV_IMAGE var"
[[ "$compose" == *'${MV_CONFIG_HOME}'* ]] && ok "compose config mount uses MV_CONFIG_HOME" || fail "compose missing MV_CONFIG_HOME var"
echo "$compose" | grep -qE 'container_name:[[:space:]]*mediavault' && ok "container_name=mediavault" || fail "bad container_name"

gi="$(cat "$ROOT/.gitignore")"
for pat in '.env' 'config/providers' 'metadata' '*.mp4' '_skip-log.txt'; do
  [[ "$gi" == *"$pat"* ]] && ok "gitignore has $pat" || fail "gitignore missing $pat"
done

# Fast sensitive scan via Python (Base64 payloads stripped)
SCAN_RC=0
python3 - "$ROOT" <<'PY' || SCAN_RC=$?
import base64, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
forbidden = [
    base64.b64decode(x).decode("utf-8")
    for x in [
        "c3Rhc2g=", "cG9ybg==", "amF2", "Z2F5", "aG9tbw==",
        "c3RyYWlnaHQ=", "YWR1bHQ=", "eHh4", "c2NyYXBlcg==", "cGVhY2g=", "55Wq5Y+3",
    ]
]
exclude_names = {"_skip-log.txt", "_install-log.txt", "provider-list.b64.txt", "_OUT.txt"}
exts = {".md", ".yml", ".yaml", ".ps1", ".sh", ".example", ".json", ".txt", ".gitignore"}
b64_re = re.compile(r"[A-Za-z0-9+/]{8,}={0,2}")
failed = 0

def fail(msg):
    global failed
    print(f"FAIL  {msg}")
    failed += 1

def ok(msg):
    print(f"OK    {msg}")

files = []
for p in root.rglob("*"):
    if not p.is_file():
        continue
    if ".git" in p.parts:
        continue
    if "config" in p.parts and "providers" in p.parts and p.name not in {".gitkeep"}:
        # skip installed provider payloads under config/providers except gitkeep
        if p.parent.name == "providers" or "providers" in p.parts:
            # allow only .gitkeep under providers
            if p.name != ".gitkeep":
                continue
    if p.name in exclude_names:
        continue
    if p.name == ".gitignore" or p.name.startswith(".env") or p.suffix.lower() in exts:
        files.append(p)

for f in files:
    rel = str(f.relative_to(root)).replace("\\", "/")
    name_l = f.name.lower()
    for word in forbidden:
        w = word.lower()
        if re.search(rf"(^|[^a-z0-9]){re.escape(w)}([^a-z0-9]|$)", name_l):
            fail(f"sensitive token in filename {rel}")
    try:
        text = f.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        fail(f"unreadable {rel}: {e}")
        continue
    for i, line in enumerate(text.splitlines(), 1):
        scrub = b64_re.sub("B64", line)
        lower = scrub.lower()
        for word in forbidden:
            w = word.lower()
            if re.search(rf"(^|[^a-z0-9]){re.escape(w)}([^a-z0-9]|$)", lower):
                fail(f"sensitive token in {rel}:{i}")
            elif any("\u4e00" <= ch <= "\u9fff" for ch in word) and word in scrub:
                fail(f"sensitive CJK in {rel}:{i}")

sys.exit(1 if failed else 0)
PY

if [[ $SCAN_RC -ne 0 ]]; then
  # recount from python printed FAILs already; bump failed at least 1 if scan failed
  # extract count
  cnt="$(python3 - "$ROOT" <<'PY'
import base64, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
forbidden = [base64.b64decode(x).decode('utf-8') for x in ["c3Rhc2g=","cG9ybg==","amF2","Z2F5","aG9tbw==","c3RyYWlnaHQ=","YWR1bHQ=","eHh4","c2NyYXBlcg==","cGVhY2g=","55Wq5Y+3"]]
exclude_names = {"_skip-log.txt","_install-log.txt","provider-list.b64.txt","_OUT.txt"}
exts = {".md",".yml",".yaml",".ps1",".sh",".example",".json",".txt",".gitignore"}
b64_re = re.compile(r"[A-Za-z0-9+/]{8,}={0,2}")
n=0
for p in root.rglob("*"):
  if not p.is_file() or ".git" in p.parts: continue
  if "providers" in p.parts and p.name != ".gitkeep": continue
  if p.name in exclude_names: continue
  if not (p.name==".gitignore" or p.name.startswith(".env") or p.suffix.lower() in exts): continue
  name_l=p.name.lower()
  for word in forbidden:
    w=word.lower()
    if re.search(rf"(^|[^a-z0-9]){re.escape(w)}([^a-z0-9]|$)", name_l): n+=1
  text=p.read_text(encoding="utf-8", errors="replace")
  for i,line in enumerate(text.splitlines(),1):
    scrub=b64_re.sub("B64", line); lower=scrub.lower()
    for word in forbidden:
      w=word.lower()
      if re.search(rf"(^|[^a-z0-9]){re.escape(w)}([^a-z0-9]|$)", lower): n+=1
      elif any("\u4e00"<=ch<="\u9fff" for ch in word) and word in scrub: n+=1
print(n)
PY
)"
  failed=$((failed + cnt))
else
  ok "sensitive scan clean"
fi

# start scripts encoded blobs
for s in start.ps1 start.sh; do
  raw="$(cat "$ROOT/scripts/$s")"
  [[ "$raw" == *'c3Rhc2hhcHAvc3Rhc2g6bGF0ZXN0'* ]] && ok "$s has encoded image" || fail "$s missing encoded image blob"
  [[ "$raw" == *'L3Jvb3QvLnN0YXNo'* ]] && ok "$s has encoded config home" || fail "$s missing encoded config home"
done

for s in install-providers.ps1 install-providers.sh; do
  raw="$(cat "$ROOT/scripts/$s")"
  echo "$raw" | grep -q 'primary' && echo "$raw" | grep -q 'alternate' && echo "$raw" | grep -q 'all' \
    && ok "$s has Profile primary|alternate|all" || fail "$s missing Profile"
  echo "$raw" | grep -q 'provider-list.b64.txt' && ok "$s references shared list" || fail "$s missing shared list ref"
  echo "$raw" | grep -q '_skip-log.txt' && ok "$s skip-log under providers" || fail "$s missing skip-log"
  echo "$raw" | grep -q 'Q29tbXVuaXR5U2NyYXBlcnM' && ok "$s has encoded community marker" || fail "$s missing community encoding"
done

for s in update.ps1 update.sh; do
  raw="$(cat "$ROOT/scripts/$s")"
  echo "$raw" | grep -q 'git pull' && ok "$s has git pull" || fail "$s missing git pull"
  echo "$raw" | grep -q 'compose pull' && ok "$s has compose pull" || fail "$s missing compose pull"
  echo "$raw" | grep -Eqi 'SkipProviders' && ok "$s has SkipProviders" || fail "$s missing SkipProviders"
done

for s in first-run-checklist.ps1 first-run-checklist.sh; do
  raw="$(cat "$ROOT/scripts/$s")"
  echo "$raw" | grep -Eqi 'OpenDocs' && ok "$s has OpenDocs" || fail "$s missing OpenDocs"
  echo "$raw" | grep -q '/data/primary' && echo "$raw" | grep -q '/data/alternate' \
    && ok "$s mentions both library paths" || fail "$s missing library paths"
  echo "$raw" | grep -Eq 'Reload|Scan' && ok "$s mentions Reload/Scan" || fail "$s missing Reload/Scan"
done

readme="$(cat "$ROOT/README.md")"
echo "$readme" | grep -q '日常更新' && echo "$readme" | grep -q 'git pull' \
  && echo "$readme" | grep -q 'install-providers' && echo "$readme" | grep -q 'compose pull' \
  && ok "README has daily update block" || fail "README missing daily update"
echo "$readme" | grep -Eqi 'Windows|\.ps1' && echo "$readme" | grep -Eqi 'Linux|macOS|\.sh' \
  && ok "README mentions Windows ps1 + Linux/macOS sh" || fail "README missing platform script notes"

setup="$(cat "$ROOT/docs/setup.md")"
echo "$setup" | grep -q '\-Profile' && echo "$setup" | grep -q 'first-run-checklist' \
  && ok "setup.md documents Profile + checklist" || fail "setup.md missing Profile or checklist"
echo "$setup" | grep -Eqi '\.ps1' && echo "$setup" | grep -Eqi '\.sh' \
  && ok "setup.md documents ps1 + sh" || fail "setup.md missing ps1/sh notes"

cnt="$(grep -E '^[A-Za-z0-9+/=]{8,}$' "$ROOT/presets/provider-list.b64.txt" | wc -l | tr -d ' ')"
[[ "$cnt" -ge 30 ]] && ok "provider-list.b64.txt has $cnt entries" || fail "provider-list.b64.txt too few ($cnt)"

echo ""
if [[ "$failed" -gt 0 ]]; then
  echo "sanity-check FAILED: $failed issue(s)"
  exit 1
else
  echo "sanity-check PASSED"
  exit 0
fi
