# Checks every live /compare/ page has valid FAQPage JSON-LD (>=3 Q&As). Run after deploys: python3 scripts/faqcheck.py
import re,json,urllib.request,sys
base='https://biff-cloud.github.io/bookkeeper-ai/compare/'
idx=urllib.request.urlopen(base).read().decode()
slugs=sorted(set(re.findall(r'/bookkeeper-ai/compare/([a-z0-9-]+)/',idx)))
bad=0
for s in slugs:
    h=urllib.request.urlopen(base+s+'/').read().decode()
    blocks=re.findall(r'<script type="application/ld\+json">(.*?)</script>',h,re.S)
    faq=[json.loads(b) for b in blocks if 'FAQPage' in b]
    n=len(faq[0]['mainEntity']) if faq else 0
    ok=faq and n>=3 and all(q['name'] and q['acceptedAnswer']['text'] for q in faq[0]['mainEntity'])
    if not ok: bad+=1; print('BAD',s,n)
print(len(slugs),'pages, bad',bad)
