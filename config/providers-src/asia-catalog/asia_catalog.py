#!/usr/bin/env python3
# MediaVault asia-catalog helper: parse Asian catalog codes, fill URL templates.
# stdin: JSON from catalog runtime; stdout: JSON fragments. Progress on stderr.
from __future__ import annotations

import base64
import json
import re
import sys
from typing import Any, Dict, List, Optional

# URL templates (Base64). Placeholders: {code} {code_lower} {code_compact}
_TEMPLATE_B64 = [
    "aHR0cHM6Ly93d3cuamF2YnVzLmNvbS97Y29kZX0=",
    "aHR0cHM6Ly9qYXZkYi5jb20vc2VhcmNoP3E9e2NvZGV9",
    "aHR0cHM6Ly9yMTguZGV2L3ZpZGVvcy92b2QvbW92aWVzL2RldGFpbC8tL2lkPXtjb2RlX2xvd2VyfS8=",
]

# ABC-123 / ABCD_001 / abc123 etc.
_CODE_RE = re.compile(
    r"(?i)(?<![A-Z0-9])([A-Z]{2,10})[-_\s]?(\d{2,5})(?![A-Z0-9])"
)


def _log(msg: str) -> None:
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()


def _templates() -> List[str]:
    out: List[str] = []
    for b in _TEMPLATE_B64:
        try:
            out.append(base64.b64decode(b).decode("utf-8"))
        except Exception as exc:  # noqa: BLE001
            _log(f"template decode skip: {exc}")
    return out


def normalize_code(raw: str) -> Optional[str]:
    if not raw:
        return None
    m = _CODE_RE.search(raw.replace(".", " ").replace("/", " "))
    if not m:
        return None
    prefix, digits = m.group(1).upper(), m.group(2)
    return f"{prefix}-{digits}"


def fill_urls(code: str) -> List[str]:
    compact = code.replace("-", "")
    lower = code.lower()
    urls: List[str] = []
    for tpl in _templates():
        urls.append(
            tpl.replace("{code}", code)
            .replace("{code_lower}", lower)
            .replace("{code_compact}", compact)
        )
    return urls


def scene_stub(code: str, extra_url: Optional[str] = None) -> Dict[str, Any]:
    urls = fill_urls(code)
    if extra_url and extra_url not in urls:
        urls.insert(0, extra_url)
    return {
        "title": code,
        "code": code,
        "urls": urls,
        "url": urls[0] if urls else None,
        "details": f"Asia catalog skeleton for {code}. Replace fetch_detail for live parse.",
    }


def read_input() -> Any:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    return json.loads(raw)


def extract_from_scene(obj: Dict[str, Any]) -> Optional[str]:
    for key in ("title", "code", "name"):
        v = obj.get(key)
        if isinstance(v, str):
            c = normalize_code(v)
            if c:
                return c
    files = obj.get("files") or []
    if isinstance(files, list):
        for f in files:
            if isinstance(f, dict):
                for key in ("path", "basename", "name"):
                    v = f.get(key)
                    if isinstance(v, str):
                        c = normalize_code(v)
                        if c:
                            return c
            elif isinstance(f, str):
                c = normalize_code(f)
                if c:
                    return c
    for key in ("path", "filename", "url"):
        v = obj.get(key)
        if isinstance(v, str):
            c = normalize_code(v)
            if c:
                return c
    return None


def fetch_detail(code: str) -> Dict[str, Any]:
    """Placeholder: return stub only. Hook HTTP/HTML parse here if needed."""
    return scene_stub(code)


def cmd_search(data: Any) -> List[Dict[str, Any]]:
    name = ""
    if isinstance(data, dict):
        name = str(data.get("name") or data.get("title") or "")
    code = normalize_code(name)
    if not code:
        _log(f"no catalog code in query: {name!r}")
        return []
    return [fetch_detail(code)]


def cmd_query(data: Any) -> Dict[str, Any]:
    if not isinstance(data, dict):
        return {}
    code = extract_from_scene(data)
    if not code:
        _log("no catalog code in scene fragment")
        return {}
    return fetch_detail(code)


def cmd_url(data: Any) -> Dict[str, Any]:
    if not isinstance(data, dict):
        return {}
    url = str(data.get("url") or "")
    code = normalize_code(url) or extract_from_scene(data)
    if not code:
        _log(f"no catalog code in url: {url!r}")
        return {}
    return scene_stub(code, extra_url=url or None)


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "search"
    data = read_input()
    if mode == "search":
        print(json.dumps(cmd_search(data), ensure_ascii=False))
    elif mode in ("query", "fragment"):
        print(json.dumps(cmd_query(data), ensure_ascii=False))
    elif mode == "url":
        print(json.dumps(cmd_url(data), ensure_ascii=False))
    else:
        _log(f"unknown mode: {mode}")
        print("{}")
        sys.exit(1)


if __name__ == "__main__":
    main()
