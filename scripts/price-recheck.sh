#!/usr/bin/env bash
# Recheck listed vendor prices against their public pages (idle sessions).
# Writes each fetch to a temp file (large SPA HTML is unreliable in bash vars).
# Exit 0 if every expected string is present; 1 on miss or fetch failure.
# Usage: bash site/scripts/price-recheck.sh [slug ...]
set -euo pipefail
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Format: slug#url#needle1#needle2#...
CHECKS=(
  'digits#https://digits.com/pricing#$65#$100#$250#Coming soon'
  'booke-ai#https://booke.ai/en-us/pricing#$129'
  'truewind#https://www.truewind.ai/pricing#Talk with the team about pricing'
  'docyt#https://docyt.com/pricing#Why is there no price on this page?'
  'financial-cents#https://financial-cents.com/pricing/#$19#$49#$69#$5'
  'uncat#https://uncat.com#$9'
  'client-hub#https://www.clienthub.app/pricing#$49#$59#$79#$99'
  'liscio#https://www.liscio.me/pricing#$19#$49#$7'
  'karbon#https://karbonhq.com/pricing/#$59/month'
  'double#https://keeper.app/pricing#mix-and-match'
  'botkeeper#https://www.botkeeper.com/pricing#$149#$79#$59#$134#$71#$53'
  'xenett#https://xenett.com/pricing#$7.5#$10'
)

want=("$@")
fail=0
ran=0

for row in "${CHECKS[@]}"; do
  slug="${row%%#*}"; rest="${row#*#}"
  url="${rest%%#*}"; rest="${rest#*#}"
  if [ ${#want[@]} -gt 0 ]; then
    keep=0
    for w in "${want[@]}"; do [ "$w" = "$slug" ] && keep=1 && break; done
    [ "$keep" = 1 ] || continue
  fi
  ran=$((ran + 1))
  out="$TMPDIR/$slug.html"
  code=$(curl -sL -A "$UA" --max-time 25 -o "$out" -w '%{http_code}' "$url" || echo 000)
  if [ ! -s "$out" ] || [ "$code" != 200 ]; then
    echo "FAIL $slug fetch $url (http $code)"
    fail=$((fail + 1))
    continue
  fi
  ok=1
  while [ -n "$rest" ]; do
    case "$rest" in
      *\#*) needle="${rest%%#*}"; rest="${rest#*#}" ;;
      *) needle="$rest"; rest="" ;;
    esac
    if ! grep -Fq -- "$needle" "$out"; then
      echo "FAIL $slug missing: $needle"
      ok=0
    fi
  done
  if [ "$ok" = 1 ]; then
    echo "OK $slug"
  else
    fail=$((fail + 1))
  fi
done

if [ "$ran" = 0 ]; then
  echo "no vendors matched; known: digits booke-ai truewind docyt financial-cents uncat client-hub liscio karbon double botkeeper xenett"
  exit 1
fi
echo "price-recheck: $ran checked, $fail failed"
[ "$fail" = 0 ]
