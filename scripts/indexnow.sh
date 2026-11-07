#!/usr/bin/env bash
# Ping IndexNow (Bing, Yandex, others) with every URL in the live sitemap. Run after a deploy.
set -euo pipefail
K=342c5310e88644dd852cb09387b16dae
B=https://biff-cloud.github.io/bookkeeper-ai
read -r n urls < <(curl -s "$B/sitemap-0.xml" | python3 -c '
import sys,re,json
urls=re.findall(r"<loc>([^<]+)</loc>", sys.stdin.read())
print(len(urls), json.dumps(urls))
')
echo "urls $n"
body="{\"host\":\"biff-cloud.github.io\",\"key\":\"$K\",\"keyLocation\":\"$B/$K.txt\",\"urlList\":$urls}"
for ep in api.indexnow.org www.bing.com yandex.com; do
  echo "$ep $(curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json; charset=utf-8' --data "$body" https://$ep/indexnow)"
done
