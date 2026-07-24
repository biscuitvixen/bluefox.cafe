#!/usr/bin/env sh
# Build-time CSP guard for the Hugo output. Asserts the built site cannot
# violate the strict CSP served by Caddy: no inline styles, and the only inline
# script is the known pre-paint bootstrap whose sha256 matches script-src in the
# Caddyfile. Run by deploy.sh before publishing, and by CI.
#
# The Caddyfile cross-check makes the CSP the single source of truth for the
# hash: edit the inline bootstrap without updating script-src and the deploy
# fails here instead of silently blocking the script in browsers. When the
# Caddyfile isn't present (CI), that sub-check is skipped; the structural
# "exactly one inline script" check still runs.
#
# Usage: check-build.sh [public-dir]     (default: ./public)
set -eu

PUBLIC="${1:-public}"
CADDYFILE="${CADDYFILE:-$HOME/fox_cafe/prod/caddy/Caddyfile}"
[ -d "$PUBLIC" ] || { echo "no build dir: $PUBLIC" >&2; exit 2; }

fails=0

# 1. No inline styles anywhere.
if grep -rEl '<style|style=' "$PUBLIC" --include='*.html' >/dev/null 2>&1; then
    echo "FAIL inline <style>/style= present in:"
    grep -rEl '<style|style=' "$PUBLIC" --include='*.html' | sed 's/^/  /'
    fails=$((fails + 1))
else
    echo "PASS no inline styles"
fi

# 2. Exactly one distinct inline <script>, matching the Caddyfile's sha256.
if python3 - "$PUBLIC" "$CADDYFILE" <<'PY'
import sys, re, glob, os, hashlib, base64
public, caddyfile = sys.argv[1], sys.argv[2]
pat = re.compile(r'<script>(.*?)</script>', re.S)  # bare <script> only, no attrs
hashes = {}
for f in glob.glob(os.path.join(public, '**', '*.html'), recursive=True):
    for body in pat.findall(open(f, encoding='utf-8').read()):
        h = base64.b64encode(hashlib.sha256(body.encode()).digest()).decode()
        hashes.setdefault(h, []).append(f)
if len(hashes) == 0:
    print("PASS no inline scripts"); sys.exit(0)
if len(hashes) > 1:
    print(f"FAIL {len(hashes)} distinct inline scripts (expected 1):")
    for h, fs in hashes.items():
        print(f"  sha256-{h}  e.g. {fs[0]}")
    sys.exit(1)
h = next(iter(hashes))
print(f"PASS one inline script: sha256-{h}")
if not os.path.exists(caddyfile):
    print("SKIP Caddyfile cross-check (not present)"); sys.exit(0)
m = re.search(r"script-src[^;]*'sha256-([A-Za-z0-9+/=]+)'", open(caddyfile).read())
if not m:
    print(f"FAIL no sha256 on script-src in {caddyfile}"); sys.exit(1)
if m.group(1) != h:
    print(f"FAIL inline hash != Caddyfile script-src (has {m.group(1)}); update the CSP hash"); sys.exit(1)
print("PASS inline hash matches Caddyfile script-src"); sys.exit(0)
PY
then :; else fails=$((fails + 1)); fi

if [ "$fails" -eq 0 ]; then
    echo "== build check OK =="
else
    echo "== build check FAILED ($fails) =="
    exit 1
fi
