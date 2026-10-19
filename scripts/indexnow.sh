#!/usr/bin/env bash
# Ping IndexNow (Bing, Yandex, others) with every URL in the live sitemap. Run after a deploy.
set -euo pipefail
K=342c5310e88644dd852cb09387b16dae
B=https://biff-cloud.github.io/bookkeeper-ai
urls=$(curl -s "$B/sitemap-0.xml" | grep -o '<loc>[^<]*' | sed 's/<loc>//' | python3 -c 'import sys,json;print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')
body="{\"host\":\"biff-cloud.github.io\",\"key\":\"$K\",\"keyLocation\":\"$B/$K.txt\",\"urlList\":$urls}"
for ep in api.indexnow.org www.bing.com yandex.com; do
  echo "$ep $(curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json; charset=utf-8' --data "$body" https://$ep/indexnow)"
done
