#!/usr/bin/env bash
# Checks the site before it deploys: the HTML validates, every local link
# and image resolves, the page weighs under 1.5 MB, and CNAME is
# tenmoku.dev. Run from anywhere; needs python3 and npx (Node 20+).
set -euo pipefail
cd "$(dirname "$0")/.."

HTML_VALIDATE_VERSION=11.18.0
MAX_BYTES=1500000
fail=0

echo "== CNAME"
if [[ "$(cat CNAME)" == "tenmoku.dev" ]]; then
  echo "ok: tenmoku.dev"
else
  echo "FAIL: CNAME is '$(cat CNAME)', not tenmoku.dev"; fail=1
fi

echo "== HTML (html-validate $HTML_VALIDATE_VERSION)"
if npx --yes "html-validate@$HTML_VALIDATE_VERSION" index.html; then
  echo "ok"
else
  echo "FAIL: html-validate"; fail=1
fi

echo "== Links, images and page weight"
python3 -I - "$MAX_BYTES" <<'PY' || fail=1
import os, re, sys
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote

max_bytes = int(sys.argv[1])
page = "index.html"

class Scan(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.anchors = set(), []
        self.links = []    # (url, loaded by the page?)
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            self.ids.add(a["id"])
        if tag == "a" and a.get("href"):
            self.links.append((a["href"], False))
        if tag == "link" and a.get("href"):
            rel = (a.get("rel") or "").split()
            loaded = bool({"stylesheet", "icon", "apple-touch-icon", "preload"} & set(rel))
            self.links.append((a["href"], loaded))
        if tag in ("img", "script") and a.get("src"):
            self.links.append((a["src"], True))
        if tag in ("img", "source") and a.get("srcset"):
            for part in a["srcset"].split(","):
                self.links.append((part.strip().split()[0], True))

scan = Scan()
scan.feed(open(page, encoding="utf-8").read())

errors, loaded = [], {page}
def local(url):
    u = urlparse(url)
    if u.scheme or u.netloc:
        return None
    return u

for url, is_loaded in scan.links:
    u = local(url)
    if u is None:
        continue
    if not u.path:
        if u.fragment and u.fragment not in scan.ids:
            errors.append(f"broken anchor: {url}")
        continue
    path = os.path.normpath(unquote(u.path).lstrip("/")) or page
    if path.endswith("/") or os.path.isdir(path):
        path = os.path.join(path, "index.html")
    if not os.path.isfile(path):
        errors.append(f"missing: {url}")
        continue
    if is_loaded:
        loaded.add(path)

# Files a stylesheet pulls in (fonts, images).
for css in [p for p in list(loaded) if p.endswith(".css")]:
    for ref in re.findall(r"url\(\s*['\"]?([^'\")]+)['\"]?\s*\)", open(css, encoding="utf-8").read()):
        if local(ref) is None or ref.startswith("data:"):
            continue
        path = os.path.normpath(os.path.join(os.path.dirname(css), unquote(ref)))
        if not os.path.isfile(path):
            errors.append(f"missing (from {css}): {ref}")
        else:
            loaded.add(path)

# The social card is fetched by link previews, not the page: just check it.
if not os.path.isfile("assets/og.png"):
    errors.append("missing: assets/og.png")

total = sum(os.path.getsize(p) for p in loaded)
for p in sorted(loaded):
    print(f"  {os.path.getsize(p):>9,}  {p}")
print(f"  {total:>9,}  total (every file the page can load, both image sizes counted)")
if total >= max_bytes:
    errors.append(f"page weight {total:,} bytes is not under {max_bytes:,}")
for e in errors:
    print("FAIL:", e)
if errors:
    sys.exit(1)
print("ok")
PY

if [[ $fail -ne 0 ]]; then
  echo "check-site: FAILED"; exit 1
fi
echo "check-site: all checks passed"
