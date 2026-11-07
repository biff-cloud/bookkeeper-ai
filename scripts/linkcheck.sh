#!/usr/bin/env bash
# Live link check: every sitemap URL must be 200; every tools.json vendor URL reported if not 200.
# 403 from Cloudflare-fronted vendors (taxdome, canopy) is a bot block, not a dead link.
B=${1:-https://biff-cloud.github.io/bookkeeper-ai}
cd "$(dirname "$0")/.."
bad=0; n=0
for u in $(curl -s "$B/sitemap-0.xml" | grep -oE '<loc>[^<]+' | sed 's/<loc>//'); do
  n=$((n+1)); c=$(curl -s -o /dev/null -m 15 -w '%{http_code}' "$u")
  [ "$c" != 200 ] && { echo "BAD $c $u"; bad=$((bad+1)); }
done
echo "internal: $n urls, $bad bad"
python3 - <<'P'
import json,glob,subprocess
f=glob.glob('src/**/tools.json',recursive=True)[0];d=json.load(open(f));d=d if isinstance(d,list) else d.get('tools',d)
ext=0
for t in d:
  u=t.get('homepage') or t.get('url')
  c=subprocess.run(['curl','-sL','-A','Mozilla/5.0','-o','/dev/null','-m','15','-w','%{http_code}',u],capture_output=True,text=True).stdout
  if c!='200': print('EXT',c,t['slug'],u); ext+=1
print(f'external: {len(d)} vendors, {ext} non-200')
P
[ "$bad" = 0 ] && [ "$n" -gt 0 ]
