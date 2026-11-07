#!/usr/bin/env bash
# Dry-run the affiliate paste path: copy site to a temp dir, flag one tool as
# affiliate with a placeholder URL, build, and assert the rendered page shows
# the label, rel=sponsored, the disclosure link, and schema keeps the homepage.
# Usage: scripts/affiliate-dryrun.sh [slug]   (default taxdome). Touches nothing live.
set -euo pipefail
slug="${1:-taxdome}"
src="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
tar -C "$src" --exclude=./dist --exclude=./node_modules -cf - . | tar -C "$tmp" -xf -
ln -s "$src/node_modules" "$tmp/node_modules"
python3 - "$tmp/src/data/tools.json" "$slug" <<'PY'
import json,sys
p,slug=sys.argv[1],sys.argv[2]
d=json.load(open(p)); hit=[t for t in d if t["slug"]==slug]
assert hit, f"no tool {slug}"
t=hit[0]; t["homepage"]=t["url"]; t["url"]="https://example.com/PASTE_PARTNER_URL"; t["urlIsAffiliate"]=True
json.dump(d,open(p,"w"))
PY
(cd "$tmp" && npx astro build >/dev/null 2>&1)
page="$tmp/dist/tools/$slug/index.html"
fail=0
chk(){ if grep -qiE "$1" "$page"; then echo "OK   $2"; else echo "FAIL $2"; fail=1; fi; }
chk 'href="https://example.com/PASTE_PARTNER_URL"' "affiliate URL on button"
chk 'rel="[^"]*sponsored' "rel=sponsored"
chk "affiliate / partner link" "visible affiliate label next to button"
chk "href=\"[^\"]*/disclosure/?\"" "link to /disclosure/ (footer)"
hp="$(python3 -c "import json;print([t for t in json.load(open('$src/src/data/tools.json')) if t['slug']=='$slug'][0]['url'])")"
if grep -o '<script type="application/ld+json">[^<]*' "$page" | grep -q "\"$hp"; then echo "OK   schema keeps homepage $hp"; else echo "FAIL schema homepage"; fail=1; fi
if grep -o '<script type="application/ld+json">[^<]*' "$page" | grep -q 'PASTE_PARTNER_URL'; then echo "FAIL affiliate URL leaked into schema"; fail=1; else echo "OK   no affiliate URL in schema"; fi
exit $fail
