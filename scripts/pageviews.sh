#!/bin/sh
# Site-wide page views (read-only; does not increment). Counter: hidden hits.sh image in Base.astro.
# Fails loudly (exit 1) if hits.sh is unreachable, so an outage is never logged as "0 views".
out=$(curl -sS -m 20 --retry 2 --retry-delay 3 https://hits.sh/api/urns/biff-cloud.github.io/bookkeeper-ai/pageviews 2>&1) \
  || { echo "ERROR: hits.sh unreachable: $out" >&2; exit 1; }
echo "$out"
