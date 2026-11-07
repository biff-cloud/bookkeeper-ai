#!/usr/bin/env bash
# One-shot idle ops check for Bookkeeper AI (no Dan, no deploy).
# Prints: pageviews, sitemap count, key live pages, IndexNow result.
# Optional: LINKCHECK=1 also runs linkcheck.sh (slower).
set -euo pipefail
cd "$(dirname "$0")/.."
B=https://biff-cloud.github.io/bookkeeper-ai

echo "== pageviews =="
bash scripts/pageviews.sh

echo "== sitemap =="
n=$(curl -s "$B/sitemap-0.xml" | python3 -c 'import sys,re; print(len(re.findall(r"<loc>([^<]+)</loc>", sys.stdin.read())))')
echo "urls $n"

echo "== live =="
for path in / /sponsor/ /compare/ /disclosure/; do
  c=$(curl -s -o /dev/null -m 15 -w '%{http_code}' "$B$path")
  echo "$c $path"
  [ "$c" = 200 ] || exit 1
done

echo "== indexnow =="
bash scripts/indexnow.sh

if [ "${LINKCHECK:-0}" = 1 ]; then
  echo "== linkcheck =="
  bash scripts/linkcheck.sh
fi

if [ "${PRICERECHECK:-0}" = 1 ]; then
  echo "== price-recheck =="
  bash scripts/price-recheck.sh
fi

echo "ops-idle OK"
